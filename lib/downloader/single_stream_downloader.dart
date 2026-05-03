import 'dart:async';
import 'dart:io';

import 'package:udm/downloader/downloader.dart';
import 'package:udm/head_parser.dart';
import 'package:udm/helpers/terminal_helpers/terminal_helper.dart';
import 'package:udm/models/downloader_config.dart';

/// A single stream download class
/// it extends the downloader class and implements the start method

class SingleStreamDownloader extends Downloader {
  SingleStreamDownloader({required super.url, DownloaderConfig? config})
    : super(config: config);

  // We can reuse the same client in the single stream so we create a shared client instance
  final HttpClient _client = HttpClient()
    ..maxConnectionsPerHost = 3
    ..connectionTimeout = const Duration(seconds: 10)
    ..idleTimeout = const Duration(seconds: 5);

  @override
  Future<void> tryHeadRequest() async {
    headerInfo = await sendHeadRequest(url, _client, logBuffer);
  }

  @override
  Future<void> timerFunction(Timer timer) async {
    status.timerTick(timerInterval);

    if (stdout.hasTerminal) {
      if (status.isCompleted) {
        showFinalProgress();
        await cleanup();
      } else {
        showProgress();
      }
    }
  }

  @override
  Future<void> start() async {
    await init();

    logBuffer.writeInfo("Starting download...");
    status.markStarted();
    logBuffer.cleanln(5); // 5 for those header info lines
    logBuffer.clean();

    final request = await _client.getUrl(url);
    final response = await request.close();

    if (response.statusCode != HttpStatus.ok) {
      status.markCancelled();
      throw Exception("Failed to download file");
    }

    await for (var chunks in response) {
      if (status.isPaused) {
        await status.waitUntilResume();
      }

      if (status.isCancelled) {
        await cleanup();
        break;
      }

      await raf.writeFrom(chunks);
      status.increment(chunks.length);
    }

    status.markCompleted();
  }

  @override
  Future<void> cleanup() async {
    super.cleanup();
    _client.close();
  }

  @override
  void showProgress() {
    if (isInitialising) return;

    final buffer = StringBuffer();

    // Line 1: Filename and Size
    buffer.writeln("File: $filename | (${status.sizeLeftText})");

    // Line 2: The actual Progress Bar
    // Using status.showProgress() or makeProgressBar()
    buffer.writeln(status.makeProgressBar());

    // Line 3: Controls menu
    buffer.write("\nControls: [p] Pause | [r] Resume | [c] Cancel");

    final output = buffer.toString();
    logBuffer.cleanLastLinesAndPrint(output);
  }

  @override
  void showFinalProgress() {
    StringBuffer buffer = StringBuffer();

    buffer.writeln("Downloaded: $filename (${absolutePath})");
    buffer.writeln(
      "Time Taken: ${status.timeTaken} || Average Speed: ${status.averageSpeedText}",
    );

    final output = buffer.toString();
    logBuffer.cleanLastLinesAndPrint(output);
  }
}
