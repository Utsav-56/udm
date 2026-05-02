import 'dart:async';
import 'dart:io';

import 'package:udm/head_parser.dart';
import 'package:udm/helpers/extensions/date_extensions.dart';
import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/helpers/terminal_helpers/terminal_helper.dart';
import 'package:udm/models/downloader_config.dart';

/// A base class for the downloader
/// the multiThreadDownloader and Single downloader should be the child classes of this clas

/// The blueprint for all Downloader implementations.
/// This handles the state management and provides a stream for progress updates.
abstract class Downloader {
  final DownloaderConfig config;

  // State and progress Tracking
  late final DownloadStatus status;

  Downloader({
    required this.config,
    this.timerInterval = const Duration(milliseconds: 300),
  });

  /// a buffer to store the terminal buffer
  final logBuffer = LogBuffer();

  /// The external API to listen for progress updates.
  Stream<DownloadStatus> get progressStream => status.stream;

  Timer? _timer;
  final Duration timerInterval;

  bool get isPaused => status.isPaused;
  bool get isCancelled => status.isCancelled;
  bool get isCompleted => status.isCompleted;
  bool get isDownloading => status.isDownloading;
  bool get isInitialising => status.isInit;

  @override
  bool get isVerboseMode => config.verbose;

  // save path helpers
  HeaderInfo? _headerInfo;
  HeaderInfo? get headerInfo => _headerInfo;
  set headerInfo(HeaderInfo headerInfo) {
    _headerInfo = headerInfo;
    if (config.filename.isEmpty) {
      config.filename = headerInfo.filename ?? "Udm-downloaded-file";
    }
  }

  String get filename => config.filename!;
  String get absolutePath => config.absoluteFilename;

  final Completer<void> _initCompleter = Completer<void>();

  // file handler
  RandomAccessFile? _raf;
  RandomAccessFile get raf => _raf!;

  /// Starts the download process.
  Future<void> start();

  /// Pauses the current data stream.
  void pause() => status.markPaused();
  void resume() => status.markResumed();

  /// Cancels the download and triggers cleanup.
  Future<void> cancel() async {
    status.markCancelled();
    await cleanup();
  }

  Future<void> tryHeadRequest();

  Future<void> init() async {
    await tryHeadRequest();

    logBuffer.writeln(
      "Headers fetched successfully\n"
      "Filename: ${headerInfo?.filename}\n"
      "File Size: ${headerInfo?.fileSize.humanReadable}\n"
      "URL: ${config.url}",
    );

    status = DownloadStatus(totalSize: headerInfo!.fileSize.bytes);

    await _prepareFile();

    _timer = Timer.periodic(timerInterval, (_) async {
      status.timerTick(timerInterval);
      if (stdout.hasTerminal) {
        if (status.isCompleted) {
          showFinalProgress();
          await cleanup();
        } else {
          showProgress();
        }
      }
    });

    _initCompleter.complete();
  }

  void showFinalProgress();

  /// Allocates space on the disk before downloading starts.
  /// This ensures we don't run out of space halfway through.
  Future<void> _prepareFile() async {
    final file = File(absolutePath);
    if (!await file.parent.exists()) {
      logBuffer.writeln("Directory not found, creating directory");
      await file.parent.create(recursive: true);
    }

    if (headerInfo?.fileSize.bytes == -1) {
      logBuffer.writeError(
        "Cannot prepare file: unknown file size {${headerInfo?.fileSize.bytes}}, trying to proceed",
      );
      // we dont know the file size so we cant prepare but we wont stop
      // because the download can still go on
      // we just ignore the file size
      return;
    }

    _raf = await file.open(mode: FileMode.writeOnly);
    await _raf!.truncate(headerInfo!.fileSize.bytes);
  }

  /// Logic to delete partial files or close ports upon cancellation.
  Future<void> cleanup() async {
    await _raf?.close();
    await status.dispose();
    _timer?.cancel();
  }

  void showProgress();
}

enum DownloadState { initial, downloading, paused, cancelled, completed }

/// the status class of the download
/// it holds the overall progress of the download
/// and the speed of the download
///
class DownloadStatus {
  final int totalSize; // the final size a chunk is assigned to download
  int totalBytesDownloaded = 0; // the overall progress of download
  int _previousBytesDownloaded = 0; // field needed for calculating speed in timer tick

  // Speed is now accurately normalized to Bytes Per Second
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

  /// downloader state
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
  bool get isInit => state == DownloadState.initial;

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

  DownloadStatus({required this.totalSize});

  void update(int bytesReceived) {
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

    if (totalBytesDownloaded == totalSize) {
      updateState(DownloadState.completed);
    }

    _notify();
  }

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(this);
    }
  }

  /// unified method for showing progress
  String showProgress() {
    if (totalBytesDownloaded == totalSize) {
      updateState(DownloadState.completed);
    }
    switch (state) {
      case DownloadState.initial:
        return "Initiating download...";
      case DownloadState.downloading:
        return makeProgressBar();
      case DownloadState.paused:
        return makePausedBar();
      case DownloadState.cancelled:
        return makeCancelledBar();
      case DownloadState.completed:
        return makeCompletedBar();
    }
  }

  /// Returns a progress bar for paused state
  /// it does not show speed or eta
  /// makes following bar
  /// [=============== Paused ================]
  /// Revised internal helper to ensure bars are always cleared and consistent
  String _makeTextedBar({required String text, int? preferredWidth}) {
    final width = preferredWidth ?? (stdout.hasTerminal ? stdout.terminalColumns : 80);
    // Subtract 2 for the brackets []
    final barLength = (width - 2).clamp(10, 200);

    if (text.length >= barLength) return "[${text.substring(0, barLength)}]";

    final sideLength = (barLength - text.length) ~/ 2;
    final padding = "=" * sideLength;

    // Ensure total length matches barLength exactly even with odd numbers
    String bar = (padding + text + padding).padRight(barLength, "=");

    return "[$bar]";
  }

  String makePausedBar() => _makeTextedBar(text: " Paused ");
  String makeCancelledBar() => _makeTextedBar(text: " Cancelled ");
  String makeCompletedBar() => _makeTextedBar(text: " Completed ");

  /// makes a bar such as
  /// [██████----------] 30% | Speed: 500 KB/s | ETA: 1m 20s left
  String makeProgressBar({int? barLength, int? preferredWidth}) {
    if (isInit) {
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
