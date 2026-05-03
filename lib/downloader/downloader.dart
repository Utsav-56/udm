import 'dart:async';
import 'dart:io';

import 'package:udm/downloader/models/download_status.dart';
import 'package:udm/downloader/head_parser.dart';
import 'package:udm/helpers/path_helpers/path_helpers.dart';
import 'package:udm/helpers/terminal_helpers/terminal_helper.dart';
import 'package:udm/downloader/models/downloader_config.dart';

/// EXPORTS FOR THIS LIBRARY MODULE;
export './models/download_status.dart';
export 'multi_thread/multi_stream_downloader.dart';
export './single_thread/single_stream_downloader.dart';

/// A base class for the downloader
/// the multiThreadDownloader and Single downloader should be the child classes of this clas

/// The blueprint for all Downloader implementations.
///
/// **Why**: Provides a unified interface for both [SingleStreamDownloader] and [MultiStreamDownloader].
/// **How**: Extend this class and implement [start] and [timerFunction].
abstract class Downloader {
  late final DownloaderConfig config;

  // State and progress Tracking
  late final DownloadStatus status;

  late final Uri url;

  Downloader({required String url, DownloaderConfig? config}) {
    this.url = Uri.parse(url);
    this.config = config ?? DownloaderConfig.defaultInstance;
    logBuffer = LogBuffer(showProgressInTerminal: this.config.showProgressInTerminal);
  }

  /// a buffer to store the terminal buffer
  late final LogBuffer logBuffer;

  /// The external API to listen for progress updates.
  Stream<DownloadStatus> get progressStream => status.stream;
  Timer? _timer;

  /// the timer interval is derived from the [DownloaderConfig.progressSyncInterval]
  Duration get timerInterval => Duration(milliseconds: config.progressSyncInterval);

  bool get isPaused => status.isPaused;
  bool get isCancelled => status.isCancelled;
  bool get isCompleted => status.isCompleted;
  bool get isDownloading => status.isDownloading;
  bool get isInitialising => status.isInitialising;

  // save path helpers
  HeaderInfo? _headerInfo;
  HeaderInfo? get headerInfo => _headerInfo;
  set headerInfo(HeaderInfo info) {
    _headerInfo = info;

    String? resolvedName;

    if (!config.isFilenameSet) {
      // If user hasn't provided a filename, try header info filename
      resolvedName = info.filename;
    } else {
      // User provided a filename, let's handle the extensions
      resolvedName = config.filename;

      final String userExt = p.extension(resolvedName) ?? "";
      final String headerExt = info.fileExtension ?? "";

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

  String get filename => config.filename!;
  String get absolutePath => config.absoluteFilename;
  int get fileSize => headerInfo?.fileSize.bytes ?? 0;

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

  /// must be implemented
  /// this will fire every timerInterval
  /// used for printing log, or anything you want
  Future<void> timerFunction(Timer timer);

  Future<void> init() async {
    await tryHeadRequest();

    logBuffer.writeln(
      "Headers fetched successfully\n"
      "Filename: ${headerInfo?.filename}\n"
      "File Size: ${headerInfo?.fileSize.humanReadable}\n"
      "URL: $url",
    );

    status = DownloadStatus(totalSize: headerInfo!.fileSize.bytes);

    await _prepareFile();

    _timer = Timer.periodic(timerInterval, timerFunction);

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
