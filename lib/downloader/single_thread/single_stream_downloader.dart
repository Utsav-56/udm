// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Reliable single-stream download implementation.
///
/// This library provides the [SingleStreamDownloader] class, which fetches a file
/// using a single persistent HTTP connection. It is the most compatible method
/// for all types of servers.
library;

import 'dart:async';
import 'dart:io';

import 'package:udm/downloader/downloader.dart';
import 'package:udm/downloader/head_parser.dart';

/// A downloader that uses a single HTTP stream to fetch data.
///
/// [SingleStreamDownloader] acts as a reliable fallback for servers that do
/// not support HTTP Range requests or in constrained network environments
/// where multiple concurrent connections are restricted.
///
/// **Usage**:
/// ```dart
/// final downloader = SingleStreamDownloader(url: 'https://example.com/file.zip');
/// await downloader.start();
/// ```
class SingleStreamDownloader extends Downloader {
  /// Creates a [SingleStreamDownloader] for the given [url].
  SingleStreamDownloader({
    required super.url,
    required super.headerInfo,
    super.config,
    HttpClient? client,
  }) : _client = client ??
            (HttpClient()
              ..maxConnectionsPerHost = 3
              ..connectionTimeout = const Duration(seconds: 10)
              ..idleTimeout = const Duration(seconds: 5));

  /// Shared HTTP client for the single stream request.
  final HttpClient _client;

  @override
  Future<void> timerFunction(Timer timer) async {
    status.timerTick(timerInterval);

    if (status.isCompleted) {
      timer.cancel();
      if (stdout.hasTerminal) {
        showFinalProgress();
      }
      await cleanup();
    } else {
      if (stdout.hasTerminal) {
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

    buffer.writeln("Downloaded: $filename ($absolutePath)");
    buffer.writeln(
      "Time Taken: ${status.timeTaken} || Average Speed: ${status.averageSpeedText}",
    );

    final output = buffer.toString();
    logBuffer.cleanLastLinesAndPrint(output);
  }
}
