import 'dart:async';
import 'dart:io';

import 'package:udm/helpers/extensions/date_extensions.dart';
import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/helpers/extensions/map_extension.dart';

/// Represents the current lifecycle stage of a download process.
enum DownloadState {
  /// Initial setup, including head parsing and file allocation.
  initial,

  /// Actively fetching data from the remote server.
  downloading,

  /// Data stream is suspended but can be resumed.
  paused,

  /// Download stopped by user or fatal error; cannot be resumed from this state.
  cancelled,

  /// File fully downloaded and verified.
  completed,
}

/// the status class of the download
/// it holds the overall progress of the download
/// and the speed of the download
///
/// Tracks the real-time telemetry and state of a download.
///
/// **Why**: Centralizes progress, speed, ETA, and timing calculations.
/// **How**: Used by [Downloader] to emit updates via [stream].
class DownloadStatus {
  DownloadStatus({required this.totalSize, int? id}) {
    this.id = id ?? DateTime.now().millisecond.toInt();
  }

  factory DownloadStatus.fromMap(Map<String, dynamic> map) {
    map.ensureKeyExists(["totalSize", "id", "state"]);
    return DownloadStatus(totalSize: map["totalSize"], id: map["id"])
      ..totalBytesDownloaded = map["totalBytesDownloaded"] ?? 0
      ..state = DownloadState.values[map["state"]];
  }

  /// helper to convert the current state to a map
  /// we do not include all fields as all other fields are just derived from `totalBytesDownloaded` and `state`
  ///
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "totalBytesDownloaded": totalBytesDownloaded,
      "state": state.index,
      "totalSize": totalSize,
    };
  }

  void updateFromMap(Map<String, dynamic> map) {
    map.ensureKeyExists([
      "id",
      "state",
      "totalBytesDownloaded",
    ], "Cannot update the status from map because {{key}} is missing");
    totalBytesDownloaded = map["totalBytesDownloaded"];
    final newState = DownloadState.values[map["state"]];

    if (newState != state) {
      if (newState == DownloadState.completed) {
        markCompleted();
      } else if (newState == DownloadState.paused) {
        markPaused();
      } else if (newState == DownloadState.cancelled) {
        markCancelled();
      } else {
        updateState(newState);
      }
    }

    if (map.containsKey("bytesPerSecond")) {
      bytesPerSecond = map["bytesPerSecond"];
    }
  }

  /// updates the status from other status
  /// similar to the .copyWith  in flutter theme class
  void updateFromStatus(DownloadStatus status) {
    if (id != status.id) {
      throw Exception(
        "Status IDs do not match, trying to update this(${this.id}) with ${status.id}",
      );
    }

    // we only allow the progress from the same id to be added
    // we give full faith to the new status and blindly accept it and give pririty to that
    totalBytesDownloaded = status.totalBytesDownloaded;

    if (status.state != state) {
      if (status.state == DownloadState.completed) {
        markCompleted();
      } else if (status.state == DownloadState.paused) {
        markPaused();
      } else if (status.state == DownloadState.cancelled) {
        markCancelled();
      } else {
        updateState(status.state);
      }
    }

    // bytesPerSecond is NOT updated here because it's usually calculated by the timer in the receiver isolate
  }

  /// this increments self from the given status
  /// this does not override the current bytes download count
  /// it rather just adds on it
  void addProgressFromStatus(DownloadStatus status) {
    if (id != status.id) {
      throw Exception(
        "Status IDs do not match, trying to update this(${this.id}) with ${status.id}",
      );
    }
    final delta = status.totalBytesDownloaded - _previousSyncBytes;
    totalBytesDownloaded += delta;
    _previousSyncBytes = status.totalBytesDownloaded;
  }

  int _previousSyncBytes = 0;

  late final int id; // to identify the stream

  final int totalSize; // the final size a chunk is assigned to download
  int totalBytesDownloaded = 0; // the overall progress of download
  int _previousBytesDownloaded = 0; // field needed for calculating speed in timer tick

  /// The current transfer speed normalized to Bytes Per Second (BPS).
  ///
  /// **Why**: Standardizing on BPS allows for consistent formatting across different units (KB/s, MB/s).
  double bytesPerSecond = 0;

  // Logic Helpers
  int get bytesLeft => totalSize - totalBytesDownloaded;
  double get progressPercent =>
      totalSize > 0 ? (totalBytesDownloaded / totalSize) * 100 : 0;
  String get speedText => bytesPerSecond.toInt().humanReadableSpeed;

  /// returns the downloaded size and total size in a readable format
  /// for eg "100 MB / 200 MB"
  /// if the total size is unknown it returns "Unknown Size"
  String get sizeLeftText {
    if (totalSize <= 0) return "Unknown Size";

    final downloaded = totalBytesDownloaded.asSuitableSizeUnit;
    final total = totalSize.asSuitableSizeUnit;
    return "$downloaded / $total";
  }

  // Stream for UI listeners (broadcast allows multiple listeners like UI + Loggers)
  final StreamController<DownloadStatus> _controller =
      StreamController<DownloadStatus>.broadcast();
  Stream<DownloadStatus> get stream => _controller.stream;

  /// The current state of the download lifecycle.
  ///
  /// **Why**: Controls UI behavior (e.g., showing/hiding Pause button).
  DownloadState state = DownloadState.initial;

  void updateState(DownloadState newState) {
    if (state == DownloadState.completed || state == DownloadState.cancelled) return;
    state = newState;
    _notify();
  }

  bool get isPaused => state == DownloadState.paused;
  bool get isCancelled => state == DownloadState.cancelled;
  bool get isCompleted => state == DownloadState.completed;
  bool get isDownloading => state == DownloadState.downloading;
  bool get isInitialising => state == DownloadState.initial;

  /// state mutator
  void markPaused() {
    if (state != DownloadState.downloading) return;
    _sliceStartTime = null; // Clear the anchor
    updateState(DownloadState.paused);
  }

  void markResumed() {
    if (!isPaused) return;
    _sliceStartTime = DateTime.now();
    updateState(DownloadState.downloading);
  }

  void markCancelled() {
    _sliceStartTime = null;
    updateState(DownloadState.cancelled);
  }

  void markStarted() {
    _sliceStartTime = DateTime.now();
    updateState(DownloadState.downloading);
  }

  void markCompleted() {
    _sliceStartTime = null;
    updateState(DownloadState.completed);
  }

  /// THE TIME CALCULATOR TO KNOW THE TIME TAKEN TO COMPLETE DOWNLOAD
  Duration _accumulatedDuration = Duration.zero;
  Duration get activeDuration {
    Duration total = _accumulatedDuration;
    // If currently downloading, add the time since the last resume/start
    if (state == DownloadState.downloading && _sliceStartTime != null) {
      total += DateTime.now().difference(_sliceStartTime!);
    }
    return total;
  }

  /// the time for each slice of state,
  /// one slice is considered when the downloader state is toggled between paused and resumed
  /// we sum up the time of all slices to get the total time taken
  DateTime? __sliceStartTime;
  DateTime? get _sliceStartTime => __sliceStartTime;

  /// a smart setter to update the slice start time
  /// if we are clearing a slice i.e nullifying then we automatically add the current duration
  /// this makes the state logic simpler and more robust with DRY principle in mind
  set _sliceStartTime(DateTime? value) {
    // before nullifying the slice  flush the current progress

    // only flush if we are nullifying AND we actually had a running slice
    if (value == null && __sliceStartTime != null) {
      _accumulatedDuration += DateTime.now().difference(__sliceStartTime!);
    }

    // if we are starting a new slice, ensure we don't over-write
    // an existing one without flushing it first (optional safety)
    if (value != null && __sliceStartTime != null) {
      _accumulatedDuration += DateTime.now().difference(__sliceStartTime!);
    }

    __sliceStartTime = value;
  }

  String get timeTaken => activeDuration.readableFormat;

  String get averageSpeedText {
    final seconds = activeDuration.inSeconds;
    if (seconds <= 0) return 0.humanReadableSpeed;

    final avg = totalBytesDownloaded / seconds;
    return avg.humanReadableSpeed;
  }

  /// a simple polling with longer delays.
  /// this prevents burning cpu cycles unnecessarily
  Future<void> waitUntilResume() async {
    while (state == DownloadState.paused) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  String get eta {
    if (state == DownloadState.paused) return "Paused";
    if (bytesPerSecond <= 0) return "N/A left";

    final secondsLeft = (bytesLeft / bytesPerSecond).ceil();
    // Assuming you have this extension from before
    return secondsLeft.asReadableTimeUnit;
  }

  /// call this when you receive a chunk of data
  void increment(int bytesReceived) {
    totalBytesDownloaded += bytesReceived;
  }

  /// this will be called by the parent timer so we can assume that this is called every tick duration
  /// Called by the Downloader's timer.
  /// Pass the actual duration of the timer tick (e.g., 500ms)
  void timerTick(Duration interval) {
    final int delta = totalBytesDownloaded - _previousBytesDownloaded;
    _previousBytesDownloaded = totalBytesDownloaded;

    // Normalize to bytes per second: (bytes / ms) * 1000
    bytesPerSecond = (delta / interval.inMilliseconds) * 1000;

    if (totalBytesDownloaded >= totalSize && totalSize > 0) {
      markCompleted();
    }

    _notify();
  }

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(this);
    }
  }

  /// unified method for showing progress
  String makeProgressBar({int? barLength, int? preferredWidth}) {
    if (totalBytesDownloaded >= totalSize && totalSize > 0) {
      markCompleted();
    }
    switch (state) {
      case DownloadState.initial:
        return "Initiating download...";
      case DownloadState.downloading:
        return _makeDownloadingBar(barLength: barLength, preferredWidth: preferredWidth);
      case DownloadState.paused:
        return _makePausedBar(barLength: barLength, preferredWidth: preferredWidth);
      case DownloadState.cancelled:
        return _makeCancelledBar(barLength: barLength, preferredWidth: preferredWidth);
      case DownloadState.completed:
        return _makeCompletedBar(barLength: barLength, preferredWidth: preferredWidth);
    }
  }

  /// Returns a progress bar for paused state
  /// it does not show speed or eta
  /// makes following bar
  /// [=============== Paused ================]
  /// Revised internal helper to ensure bars are always cleared and consistent
  String _makeTextedBar({required String text, int? preferredWidth, int? barLength}) {
    final width = preferredWidth ?? (stdout.hasTerminal ? stdout.terminalColumns : 80);
    // Subtract 2 for the brackets []
    barLength = barLength ?? (width - 2).clamp(10, 200);

    if (text.length >= barLength) return "[${text.substring(0, barLength)}]";

    final sideLength = (barLength - text.length) ~/ 2;
    final padding = "=" * sideLength;

    // Ensure total length matches barLength exactly even with odd numbers
    String bar = (padding + text + padding).padRight(barLength, "=");

    return "[$bar]";
  }

  String _makePausedBar({int? barLength, int? preferredWidth}) => _makeTextedBar(
    text: " Paused ",
    barLength: barLength,
    preferredWidth: preferredWidth,
  );
  String _makeCancelledBar({int? barLength, int? preferredWidth}) => _makeTextedBar(
    text: " Cancelled ",
    barLength: barLength,
    preferredWidth: preferredWidth,
  );
  String _makeCompletedBar({int? barLength, int? preferredWidth}) => _makeTextedBar(
    text: " Completed ",
    barLength: barLength,
    preferredWidth: preferredWidth,
  );

  /// makes a bar such as
  /// [██████----------] 30% | Speed: 500 KB/s | ETA: 1m 20s left
  String _makeDownloadingBar({int? barLength, int? preferredWidth}) {
    if (isInitialising) {
      return "Initiating download..."; // we havent started download yet
    }

    String suffix = "${progressPercent.toStringAsFixed(2)}% ";
    if (!isPaused) {
      suffix += "| Speed: $speedText | ETA: $eta"; // speed is undefined in pause state
    }

    final width = preferredWidth ?? (stdout.hasTerminal ? (stdout.terminalColumns) : 80);

    /// if width is less then the suffix
    /// in short if the terminal is too small we show suffix below the bar instead of right side
    if (width < suffix.length + 10) {
      barLength = width - 3; // 2 for the brackets [] and 1 for some padding
      suffix = "\n$suffix"; // move suffix to next line
    } else {
      barLength = (width - suffix.length - 3);
    }

    final filledLength = ((progressPercent / 100) * barLength).round();

    List<String> barChars = List.generate(barLength, (i) {
      return i < filledLength ? '█' : '-';
    });

    if (isPaused) {
      final pausedText = " Paused ";
      final start = (barLength / 2 - pausedText.length / 2).floor();

      for (int i = 0; i < pausedText.length; i++) {
        if (start + i < barChars.length) {
          barChars[start + i] = pausedText[i];
        }
      }
    }

    final bar = barChars.join();
    return "[$bar] $suffix";
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

/// these methods are supposed to be helpers for multiple isolates
/// useful for isolate workers to manage all at once
extension StatusHelper on List<DownloadStatus> {
  void tickAll(Duration interval) {
    for (var status in this) {
      status.timerTick(interval);
    }
  }

  /// cancels all the statuses in the list
  /// if status working in isolate they will also be cancelled
  void cancelAll() {
    for (var status in this) {
      status.updateState(DownloadState.cancelled);
    }
  }

  ///disposes all the statuses in the list
  /// it also waits for the stream to complete
  Future<void> disposeAll() async {
    for (var status in this) {
      await status.dispose();
    }
  }

  /// makes progress strings for all the statuses
  /// can be used to display progress of all the workers in the main thread
  List<String> makeProgressAll({int? barLength, int? preferredWidth}) {
    final List<String> progressList = [];
    for (var status in this) {
      progressList.add(
        status.makeProgressBar(barLength: barLength, preferredWidth: preferredWidth),
      );
    }
    return progressList;
  }
}
