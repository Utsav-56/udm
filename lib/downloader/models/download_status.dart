// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Telemetry and lifecycle tracking for download operations.
///
/// This library provides the [DownloadStatus] class and [DownloadState] enum,
/// which are used to monitor progress, calculate speed/ETA, and manage the
/// state transitions of a download.
library;

import 'dart:async';
import 'dart:io';

import 'package:udm/helpers/extensions/date_extensions.dart';
import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/helpers/extensions/map_extension.dart';

/// Defines the possible stages of a download's lifecycle.
enum DownloadState {
  /// The downloader is preparing resources, fetching headers, or allocating disk space.
  initial,

  /// Data is being actively received and written to disk.
  downloading,

  /// The download is temporarily suspended but retains its progress.
  paused,

  /// The download was terminated by the user or due to a fatal error.
  cancelled,

  /// The download finished successfully and all data is flushed to disk.
  completed,
}

/// A comprehensive monitor for download progress and performance metrics.
///
/// [DownloadStatus] tracks bytes downloaded, calculates real-time transfer speeds,
/// estimates time remaining (ETA), and manages lifecycle state transitions. It
/// provides a broadcast [stream] for UI updates and includes built-in terminal
/// progress bar generation.
class DownloadStatus {
  /// Creates a new [DownloadStatus] with a specified [totalSize] in bytes.
  ///
  /// An optional [id] can be provided; otherwise, a unique ID is generated
  /// based on the current timestamp.
  DownloadStatus({required this.totalSize, int? id}) {
    this.id = id ?? DateTime.now().millisecond.toInt();
  }

  /// Factory constructor to reconstruct a [DownloadStatus] from a Map.
  ///
  /// Used for state restoration or communication between isolates.
  factory DownloadStatus.fromMap(Map<String, dynamic> map) {
    map.ensureKeyExists(["totalSize", "id", "state"]);
    return DownloadStatus(totalSize: map["totalSize"], id: map["id"])
      ..totalBytesDownloaded = map["totalBytesDownloaded"] ?? 0
      ..state = DownloadState.values[map["state"]];
  }

  /// Serializes the essential state into a Map.
  ///
  /// Includes [id], [totalBytesDownloaded], [state], and [totalSize]. Derived
  /// metrics like speed and ETA are excluded as they are recalculated per-tick.
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "totalBytesDownloaded": totalBytesDownloaded,
      "state": state.index,
      "totalSize": totalSize,
    };
  }

  /// Updates the current status properties from values in a Map.
  ///
  /// Throws an exception if mandatory keys are missing.
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

  /// Merges properties from another [DownloadStatus] instance.
  ///
  /// This method performs a hard update of progress and state. Throws an
  /// exception if the IDs of the two status instances do not match.
  void updateFromStatus(DownloadStatus status) {
    if (id != status.id) {
      throw Exception(
        "Status IDs do not match, trying to update this($id) with ${status.id}",
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

  /// Adds the progress delta from another [DownloadStatus] to this instance.
  ///
  /// Unlike [updateFromStatus], this performs an incremental update, which is
  /// useful when aggregating multiple worker stream progresses into an overall status.
  void addProgressFromStatus(DownloadStatus status) {
    if (id != status.id) {
      throw Exception(
        "Status IDs do not match, trying to update this($id) with ${status.id}",
      );
    }
    final delta = status.totalBytesDownloaded - _previousSyncBytes;
    totalBytesDownloaded += delta;
    _previousSyncBytes = status.totalBytesDownloaded;
  }

  int _previousSyncBytes = 0;

  /// Unique identifier for the download stream.
  late final int id;

  /// The total expected size of the download (or chunk) in bytes.
  final int totalSize;

  /// Total number of bytes downloaded and verified so far.
  int totalBytesDownloaded = 0;

  /// Progress tracker for calculating speed since the last timer tick.
  int _previousBytesDownloaded = 0;

  /// Current transfer speed in bytes per second.
  double bytesPerSecond = 0;

  // Logic Helpers
  /// Remaining bytes to be downloaded.
  int get bytesLeft => totalSize - totalBytesDownloaded;

  /// Progress as a percentage (0.0 to 100.0).
  double get progressPercent =>
      totalSize > 0 ? (totalBytesDownloaded / totalSize) * 100 : 0;

  /// Human-readable speed string (e.g., "1.2 MB/s").
  String get speedText => bytesPerSecond.toInt().humanReadableSpeed;

  /// Formatted string representing downloaded size vs total size.
  ///
  /// Example: "10.5 MB / 100.0 MB". Returns "Unknown Size" if total size is invalid.
  String get sizeLeftText {
    if (totalSize <= 0) return "Unknown Size";

    final downloaded = totalBytesDownloaded.asSuitableSizeUnit;
    final total = totalSize.asSuitableSizeUnit;
    return "$downloaded / $total";
  }

  /// Broadcast stream providing real-time updates of this status object.
  final StreamController<DownloadStatus> _controller =
      StreamController<DownloadStatus>.broadcast();

  /// External access to the progress stream.
  Stream<DownloadStatus> get stream => _controller.stream;

  /// Current stage of the download lifecycle.
  DownloadState state = DownloadState.initial;

  /// Transition to a new [DownloadState] and notify stream listeners.
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

  /// Transitions the state to [DownloadState.paused].
  void markPaused() {
    if (state != DownloadState.downloading) return;
    _sliceStartTime = null; // Clear the anchor
    updateState(DownloadState.paused);
  }

  /// Transitions the state back to [DownloadState.downloading].
  void markResumed() {
    if (!isPaused) return;
    _sliceStartTime = DateTime.now();
    updateState(DownloadState.downloading);
  }

  /// Transitions the state to [DownloadState.cancelled].
  void markCancelled() {
    _sliceStartTime = null;
    updateState(DownloadState.cancelled);
  }

  /// Transitions the state to [DownloadState.downloading] from initial.
  void markStarted() {
    _sliceStartTime = DateTime.now();
    updateState(DownloadState.downloading);
  }

  /// Transitions the state to [DownloadState.completed].
  void markCompleted() {
    _sliceStartTime = null;
    updateState(DownloadState.completed);
  }

  /// Formatted string representing the average speed over the entire session.
  String get averageSpeedText {
    final seconds = activeDuration.inSeconds;
    if (seconds <= 0) return 0.humanReadableSpeed;

    final avg = totalBytesDownloaded / seconds;
    return avg.humanReadableSpeed;
  }

  /// Helper that yields control until the download state is no longer [DownloadState.paused].
  Future<void> waitUntilResume() async {
    while (state == DownloadState.paused) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Estimated Time Arrival (ETA) as a readable string.
  ///
  /// Returns "Paused" or "N/A" if calculations are not possible.
  String get eta {
    if (state == DownloadState.paused) return "Paused";
    if (bytesPerSecond <= 0) return "N/A left";

    final secondsLeft = (bytesLeft / bytesPerSecond).ceil();
    // Assuming you have this extension from before
    return secondsLeft.asReadableTimeUnit;
  }

  /// Increments the total bytes downloaded.
  void increment(int bytesReceived) {
    totalBytesDownloaded += bytesReceived;
  }

  /// Periodic calculation of transfer speed and lifecycle updates.
  ///
  /// Should be called by a [Timer] at regular intervals (defined by [interval]).
  /// Automatically marks the download as completed if [totalBytesDownloaded]
  /// meets [totalSize].
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

  /// Broadcasts the current status to all stream listeners.
  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(this);
    }
  }

  /// Generates a visual progress bar string for terminal display.
  ///
  /// Adapts based on the current [state] (e.g., showing a solid bar for completed,
  /// or "Paused" text).
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

  /// Closes the internal stream controller.
  Future<void> dispose() async {
    await _controller.close();
  }
}

/// Collection of utility methods for managing a list of [DownloadStatus] instances.
///
/// Useful for orchestrating multiple worker streams in multi-threaded downloads.
extension StatusHelper on List<DownloadStatus> {
  /// Triggers a timer tick for every status in the list.
  void tickAll(Duration interval) {
    for (var status in this) {
      status.timerTick(interval);
    }
  }

  /// Transition all statuses in the list to the cancelled state.
  void cancelAll() {
    for (var status in this) {
      status.updateState(DownloadState.cancelled);
    }
  }

  /// Disposes every status instance in the list.
  Future<void> disposeAll() async {
    for (var status in this) {
      await status.dispose();
    }
  }

  /// Generates a list of formatted progress bar strings for all statuses.
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
