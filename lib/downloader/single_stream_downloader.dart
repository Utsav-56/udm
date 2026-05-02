import 'dart:io';

import 'package:udm/downloader/downloader.dart';
import 'package:udm/head_parser.dart';

/// A single stream download class
/// it extends the downloader class and implements the start method

class SingleStreamDownloader extends Downloader {
  SingleStreamDownloader({required super.config});

  // We can reuse the same client in the single stream so we create a shared client instance
  final HttpClient _client = HttpClient()
    ..maxConnectionsPerHost = 3
    ..connectionTimeout = const Duration(seconds: 10)
    ..idleTimeout = const Duration(seconds: 5);

  @override
  Future<void> tryHeadRequest() async {
    headerInfo = await sendHeadRequest(_client, config.url);
  }

  @override
  Future<void> start() async {
    await init();
    status.markStarted();

    final request = await _client.getUrl(config.url);
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
      status.update(chunks.length);
    }

    status.markCompleted();
  }

  @override
  Future<void> cleanup() async {
    super.cleanup();
    _client.close();
  }

  int _lastLineCount = 0;
  void _cleanLastLinesAndPrint(String text) {
    final currentLines = text.split('\n');

    // 1. Move cursor back to the start of our previous output block
    if (_lastLineCount > 0) {
      // \x1B[A moves cursor UP. We move up N-1 times to reach the first line we printed.
      stdout.write('\x1B[${_lastLineCount - 1}A');
    }

    // 2. Overwrite each line
    for (int i = 0; i < currentLines.length; i++) {
      // \r moves to start of line, \x1B[2K clears the line to prevent "ghost" characters
      stdout.write('\r\x1B[2K${currentLines[i]}');
      if (i < currentLines.length - 1) {
        stdout.write('\n');
      }
    }

    // Update line count for the next call (handles terminal wrapping if lines split)
    _lastLineCount = currentLines.length;
  }

  @override
  void showProgress() {
    final buffer = StringBuffer();

    // Line 1: Filename and Size
    buffer.writeln("File: $filename | (${status.sizeLeftText})");

    // Line 2: The actual Progress Bar
    // Using status.showProgress() or makeProgressBar()
    buffer.writeln(status.makeProgressBar());

    // Line 3: Controls menu
    buffer.write("Controls: [p] Pause | [r] Resume | [c] Cancel");

    final output = buffer.toString();
    _cleanLastLinesAndPrint(output);
  }

  @override
  void showFinalProgress() {
    StringBuffer buffer = StringBuffer();

    buffer.writeln("Downloaded: $filename (${absolutePath})");
    buffer.writeln(
      "Time Taken: ${status.timeTaken} || Average Speed: ${status.averageSpeedText}",
    );

    final output = buffer.toString();
    _cleanLastLinesAndPrint(output);
  }
}
