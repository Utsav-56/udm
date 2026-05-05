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
    super.status,
    super.isInitCompleted,
    HttpClient? client,
  }) : _client =
           client ??
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
      await cleanup();
    }
  }

  @override
  Future<void> start() async {
    await init();

    status.markStarted();

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
}
