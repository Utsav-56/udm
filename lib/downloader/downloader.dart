// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Core downloader abstractions and base implementation for the UDM (Universal Download Manager).
///
/// This library defines the [Downloader] base class which provides the skeletal
/// framework for implementing various download strategies, such as single-threaded
/// and multi-threaded downloads.
library;

import 'dart:async';
import 'dart:io';

import 'package:udm/downloader/models/download_status.dart';
import 'package:udm/downloader/head_parser.dart';
import 'package:udm/downloader/models/file_type_entry.dart';
import 'package:udm/helpers/path_helpers/path_helpers.dart';
import 'package:udm/downloader/models/downloader_preference.dart';

export './models/download_status.dart';
export 'multi_thread/multi_stream_downloader.dart';
export './single_thread/single_stream_downloader.dart';
export 'download_manager.dart';

/// The blueprint for all Downloader implementations in the UDM ecosystem.
///
/// This abstract class establishes a unified interface for managing download
/// lifecycles, progress tracking, and resource cleanup. It handles common
/// concerns such as filename resolution based on server headers, disk space
/// allocation, and periodic status synchronization.
///
/// **Usage**:
/// Concrete implementations (like [MultiStreamDownloader] or [SingleStreamDownloader])
/// must implement the [start], [tryHeadRequest], and [timerFunction] methods.
///
/// ```dart
/// final downloader = MyDownloader(url: 'https://example.com/file.zip');
/// await downloader.init();
/// await downloader.start();
/// ```
abstract class Downloader {
  /// Configuration settings for this downloader instance.
  ///
  /// Includes options for output directory and naming preferences.
  late final DownloaderPreference config;

  // State and progress Tracking
  /// Current state and progress metrics of the download.
  ///
  /// Tracks bytes downloaded, speed, estimated time remaining, and status flags.
  DownloadStatus? _status;

  /// status setter
  ///
  /// can be used to update the status of the download
  /// or if the download is proxied, can be used to update the status of the download
  set status(DownloadStatus? value) {
    // we cant set this if it is already set
    if (_status != null) {
      print(
        "Status is already set, trying to update it with ${value?.id}, this is not possible so we wont update it",
      );
      return;
    }

    if (value == null) return;
    _status = value;
  }

  /// status getter
  DownloadStatus get status => _status!;

  /// The remote URL of the file to be downloaded.
  late final Uri url;

  /// Information retrieved from the server headers.
  ///
  /// Contains details such as file size, filename, and range support.
  /// can be null if the head request  failed or server does not provide header info.
  HeaderInfo? headerInfo;

  /// A unique timestamped identifier for this downloader instance.
  final int id = DateTime.now().millisecondsSinceEpoch;

  /// Creates a new [Downloader] instance for the given [url] and [headerInfo].
  ///
  /// Optional [config] can be provided to customize download behavior. If omitted,
  /// [DownloaderPreference.defaultInstance] is used.
  Downloader({
    required String url,
    this.headerInfo,
    DownloaderPreference? config,

    /// if status is provided, it means that we may be proxying the download
    ///
    /// Probable usecase is when we leave the download and come back later and
    /// resume the download
    /// the status will tell us the current state of the download
    ///
    /// also if the multi thread was not supported and the progress needs  to be proxied
    /// use this in your own caution as improper status may lead to corrupted file.
    ///
    /// note: only the very first status is accepted, any subsequent status is ignored.
    DownloadStatus? status,

    /// useful if the downloader is resuming
    bool isInitCompleted = false,
  }) {
    this.url = Uri.parse(url);
    this.status = status;

    if (isInitCompleted) {
      _initCompleter.complete();
    }
  }

  /// returns true if the init completer is completed
  bool get isInitCompleted => _initCompleter.isCompleted;

  /// returns a resolved filename according to the priority chain as below
  /// [DownloaderPreference] => [HeaderInfo] => default
  String get resolvedFilename =>
      config.fileName ?? headerInfo?.filename ?? 'UDM_DOWNLOADED_FILE';

  String get fileType =>
      FileTypePreference().getType(p.extension(resolvedFilename)) ?? "";

  /// returns a resolved output directory according to the priority chain as below
  /// [DownloaderPreference] => default
  String get resolvedOutputDir =>
      config.outputDir ?? p.join(p.getDownloadDir(), fileType);

  /// the absolute filename of the file to be downloaded.
  String get absolutePath => p.join(resolvedOutputDir, resolvedFilename);

  /// A stream that emits [DownloadStatus] updates during the download process.
  Stream<DownloadStatus> get progressStream => status.stream;
  Timer? _timer;

  /// The interval at which progress is synchronized and [timerFunction] is called.
  ///
  /// Derived from [DownloaderPreference.progressSyncInterval].
  Duration get timerInterval => Duration(milliseconds: config.progressSyncInterval);

  /// Returns `true` if the download is currently paused.
  bool get isPaused => status.isPaused;

  /// Returns `true` if the download has been cancelled.
  bool get isCancelled => status.isCancelled;

  /// Returns `true` if the download has completed successfully.
  bool get isCompleted => status.isCompleted;

  /// Returns `true` if the download is actively in progress.
  bool get isDownloading => status.isDownloading;

  /// Returns `true` if the downloader is in the initialization phase.
  bool get isInitialising => status.isInitialising;

  /// The total size of the file in bytes, as reported by the server.
  int? get fileSize => headerInfo?.fileSize?.bytes;

  final Completer<void> _initCompleter = Completer<void>();

  /// The underlying [RandomAccessFile] used for disk operations.
  ///
  /// Throws a [StateError] if accessed before initialization.
  RandomAccessFile? fileHandle;
  RandomAccessFile get raf => fileHandle!;

  /// Orchestrates the download start logic.
  ///
  /// Implementation varies between single-stream and multi-stream downloaders.
  Future<void> start();

  /// Pauses the download by signaling the underlying data streams.
  void pause() => status.markPaused();

  /// Resumes a previously paused download.
  void resume() => status.markResumed();

  /// Cancels the download and triggers resource cleanup.
  ///
  /// This will stop all active streams, close file handles, and may delete
  /// partially downloaded files depending on the implementation.
  Future<void> cancel() async {
    status.markCancelled();
    await cleanup();
  }

  /// Hook that executes periodically based on [timerInterval].
  ///
  /// Concrete classes should use this to update status or perform health checks.
  Future<void> timerFunction(Timer timer);

  /// Initializes the downloader by fetching headers and preparing the local file.
  ///
  /// This method must be called before [start]. It sets up the [status]
  /// and disk allocation.
  ///
  /// Throws an exception if head request fails or file cannot be created.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // If headerInfo is missing, attempt to fetch it now
    if (headerInfo == null) {
      try {
        final client = HttpClient()
          ..connectionTimeout = Duration(seconds: config.timeout)
          ..idleTimeout = Duration(seconds: config.idleTimeout)
          ..userAgent = config.userAgent;
        headerInfo = await sendHeadRequest(url, client: client);
        client.close();
      } catch (e) {
        // Fallback or ignore? The user said "if the header info is not given... downloader is responsible to fetch it"
        // If it still fails, we continue with null headerInfo and handle it gracefully
      }
    }

    if (_status == null) {
      status = DownloadStatus(totalSize: fileSize);
    } else if (_status!.totalSize == null) {
      _status!.totalSize = fileSize;
    }

    await _prepareFile();

    _timer = Timer.periodic(timerInterval, timerFunction);

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  /// Allocates space on the disk and opens the file for writing.
  ///
  /// This pre-allocation prevents "Disk Full" errors during active downloading
  /// and ensures the file structure is ready for parallel writes in multi-stream mode.
  ///
  /// If the file size is unknown, it skips truncation but still opens the file.
  Future<void> _prepareFile() async {
    final file = File(absolutePath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    final size = fileSize;

    if (size == null || size <= 0) {
      // we dont know the file size so we cant prepare but we wont stop
      // because the download can still go on
      // we just ignore the file size and open in write mode
      fileHandle = await file.open(mode: FileMode.writeOnly);
      return;
    }

    fileHandle = await file.open(mode: FileMode.writeOnly);
    await fileHandle!.truncate(size);
  }

  bool _isInitialized = false;

  /// Releases resources used by the downloader.
  ///
  /// Closes the [RandomAccessFile], disposes the [status] stream, and cancels
  /// the internal timer.
  Future<void> cleanup() async {
    await fileHandle?.close();
    await status.dispose();
    _timer?.cancel();
  }
}
