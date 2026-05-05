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
import 'package:udm/helpers/path_helpers/path_helpers.dart';
import 'package:udm/downloader/models/downloader_config.dart';

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
  late final DownloaderConfig config;

  // State and progress Tracking
  /// Current state and progress metrics of the download.
  ///
  /// Tracks bytes downloaded, speed, estimated time remaining, and status flags.
  late final DownloadStatus status;

  /// The remote URL of the file to be downloaded.
  late final Uri url;

  /// Information retrieved from the server headers.
  ///
  /// Contains details such as file size, filename, and range support.
  final HeaderInfo headerInfo;

  /// A unique timestamped identifier for this downloader instance.
  late final String id;

  /// Creates a new [Downloader] instance for the given [url] and [headerInfo].
  ///
  /// Optional [config] can be provided to customize download behavior. If omitted,
  /// [DownloaderConfig.defaultInstance] is used.
  Downloader({required String url, required this.headerInfo, DownloaderConfig? config}) {
    id = DateTime.now().millisecondsSinceEpoch.toString();
    this.url = Uri.parse(url);
    this.config = config ?? DownloaderConfig.defaultInstance;

    _resolveFilename();

    // print(
    //   "Created Downloader with id: $id \n for url: ${url} \n for filename: ${this.config.filename}",
    // );
  }

  void _resolveFilename() {
    String? resolvedName;

    if (!config.isFilenameSet) {
      // If user hasn't provided a filename, try header info filename
      resolvedName = headerInfo.filename;
    } else {
      // User provided a filename, let's handle the extensions
      resolvedName = config.filename;

      final String userExt = p.extension(resolvedName) ?? "";
      final String headerExt = headerInfo.fileExtension ?? "";

      if (headerExt.isNotEmpty) {
        if (userExt.isEmpty) {
          // No extension in user provided filename, append header extension
          resolvedName = "$resolvedName$headerExt";
        } else if (config.preferResolvedExtension && userExt != headerExt) {
          // User provided extension but flag says prefer resolved (append)
          // e.g. demo.archive -> demo.archive.zip
          resolvedName = "$resolvedName$headerExt";
        }
      }
    }

    if (resolvedName != null && resolvedName.isNotEmpty) {
      config.filename = resolvedName;
    }
  }

  /// A stream that emits [DownloadStatus] updates during the download process.
  Stream<DownloadStatus> get progressStream => status.stream;
  Timer? _timer;

  /// The interval at which progress is synchronized and [timerFunction] is called.
  ///
  /// Derived from [DownloaderConfig.progressSyncInterval].
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

  /// The resolved filename used for saving the download.
  String get filename => config.filename;

  /// The absolute file system path where the file will be saved.
  String get absolutePath => config.absoluteFilename;

  /// The total size of the file in bytes, as reported by the server.
  int get fileSize => headerInfo.fileSize.bytes;

  final Completer<void> _initCompleter = Completer<void>();

  /// The underlying [RandomAccessFile] used for disk operations.
  ///
  /// Throws a [StateError] if accessed before initialization.
  RandomAccessFile? _raf;
  RandomAccessFile get raf => _raf!;

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
    status = DownloadStatus(totalSize: headerInfo.fileSize.bytes);

    // Lock the filename and path before starting any file operations
    config.resolveFinalPath();

    await _prepareFile();

    _timer = Timer.periodic(timerInterval, timerFunction);

    _initCompleter.complete();
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

    if (headerInfo.fileSize.bytes == -1) {
      // we dont know the file size so we cant prepare but we wont stop
      // because the download can still go on
      // we just ignore the file size
      return;
    }

    _raf = await file.open(mode: FileMode.writeOnly);
    await _raf!.truncate(headerInfo.fileSize.bytes);
  }

  /// Releases resources used by the downloader.
  ///
  /// Closes the [RandomAccessFile], disposes the [status] stream, and cancels
  /// the internal timer.
  Future<void> cleanup() async {
    await _raf?.close();
    await status.dispose();
    _timer?.cancel();
  }
}
