// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Central management system for handling concurrent downloads.
///
/// This library provides the [DownloadManager] class which implements a queued
/// execution model. It manages concurrent active downloads, fetches metadata,
/// and routes to the appropriate download strategy (multi-stream or single-stream).
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:udm/downloader/downloader.dart';
import 'package:udm/downloader/head_parser.dart';
import 'package:udm/downloader/models/downloader_config.dart';
import 'package:udm/helpers/terminal_helpers/terminal_helper.dart';

/// Represents a queued download operation awaiting execution.
///
/// Holds the target [url] and [config] while exposing a [completer] that
/// will resolve with the spawned [Downloader] instance once processing begins.
class DownloadTask {
  /// The remote URL of the file to be downloaded.
  final String url;

  /// Configuration settings for this specific download.
  final DownloaderConfig config;

  /// Resolves with the created [Downloader] instance when the task is spawned.
  final Completer<Downloader> completer = Completer<Downloader>();

  /// Creates a new [DownloadTask].
  DownloadTask({required this.url, required this.config});
}

/// The central controller for all download operations within UDM.
///
/// [DownloadManager] implements a queue system to restrict the maximum number
/// of concurrent downloads (up to [maxConcurrentDownloads]). It automatically
/// fetches file metadata via [sendHeadRequest] and spawns either a
/// [MultiStreamDownload] or [SingleStreamDownloader] based on server support.
class DownloadManager {
  /// Internal singleton instance of the [DownloadManager].
  static final DownloadManager _instance = DownloadManager._internal();

  /// Factory constructor to retrieve the singleton [DownloadManager] instance.
  factory DownloadManager() => _instance;

  /// Internal constructor for singleton initialization.
  DownloadManager._internal();

  /// A registry of all instantiated downloaders, keyed by their unique timestamped ID.
  ///
  /// This map allows external components to signal specific downloaders (e.g., pause, resume, cancel).
  final Map<String, Downloader> spawnedDownloaders = {};

  /// The log buffer used for stable terminal UI rendering.
  final LogBuffer _logBuffer = LogBuffer(showProgressInTerminal: true);

  /// Timer responsible for the periodic UI tick.
  Timer? _uiTimer;

  /// Tracks completed download operations for the UI summary.
  final List<Downloader> _finishedDownloaders = [];

  /// The internal queue of pending [DownloadTask] instances.
  final List<DownloadTask> _queue = [];

  /// The current number of active downloads being processed.
  int _activeDownloads = 0;

  /// The maximum number of downloads allowed to run concurrently.
  static const int maxConcurrentDownloads = 4;

  /// Adds a new download operation to the queue.
  ///
  /// If the number of active downloads is less than [maxConcurrentDownloads],
  /// the download starts immediately. Otherwise, it waits in the queue.
  ///
  /// Returns a [Future] that completes with the instantiated [Downloader]
  /// once the task starts executing.
  Future<Downloader> enqueue(String url, DownloaderConfig config) {
    final task = DownloadTask(url: url, config: config);
    _queue.add(task);
    _processQueue();
    return task.completer.future;
  }

  /// Processes the next available task in the queue if concurrency limits allow.
  ///
  /// Recursively triggers itself upon completion of a task to ensure continuous
  /// queue processing.
  Future<void> _processQueue() async {
    if (_activeDownloads >= maxConcurrentDownloads || _queue.isEmpty) {
      return;
    }

    _activeDownloads++;
    final task = _queue.removeAt(0);

    // Disable individual downloader terminal output so the manager can handle it centrally
    final config = task.config.copyWith(showProgressInTerminal: false);

    try {
      final downloader = await _spawnDownloader(task.url, config);
      spawnedDownloaders[downloader.id] = downloader;
      task.completer.complete(downloader);

      _startUiTimerIfNeeded();

      // We start the download and wait for it to finish before freeing the slot
      await downloader.start();
      _finishedDownloaders.add(downloader);
    } catch (e, st) {
      if (!task.completer.isCompleted) {
        task.completer.completeError(e, st);
      }
    } finally {
      _activeDownloads--;
      // Process next item in queue when current task finishes
      _processQueue();

      if (_activeDownloads == 0 && _queue.isEmpty) {
        _stopUiTimer();
        _renderUi(); // Final render
      }
    }
  }

  /// Determines the optimal download strategy and instantiates the appropriate [Downloader].
  ///
  /// This method performs an initial HEAD request to gather file metadata. It
  /// then spawns a [MultiStreamDownload] if supported by the server, otherwise
  /// defaulting to a [SingleStreamDownloader].
  Future<Downloader> _spawnDownloader(String url, DownloaderConfig config) async {
    final client = HttpClient()
      ..maxConnectionsPerHost = 3
      ..connectionTimeout = const Duration(seconds: 10)
      ..idleTimeout = const Duration(seconds: 5);

    final headerInfo = await sendHeadRequest(Uri.parse(url), client);

    Downloader downloader;

    if (headerInfo.supportsMultiStream && config.downloadType != DownloadType.single) {
      // Close the client since multi-stream isolate manages its own network connections
      client.close();
      downloader = MultiStreamDownload(url: url, headerInfo: headerInfo, config: config);
    } else {
      // Reuse the existing client for the single stream download
      downloader = SingleStreamDownloader(
        url: url,
        headerInfo: headerInfo,
        config: config,
        client: client,
      );
    }

    return downloader;
  }

  /// Starts the UI timer if it isn't already running.
  void _startUiTimerIfNeeded() {
    if (_uiTimer == null || !_uiTimer!.isActive) {
      _uiTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _renderUi());
    }
  }

  /// Stops the UI timer when no active downloads remain.
  void _stopUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = null;
  }

  /// Renders the current state of all downloads, completed tasks, and the queue
  /// using terminal-friendly UI components.
  void _renderUi() {
    if (!stdout.hasTerminal) return;

    final buffer = StringBuffer();
    final width = stdout.terminalColumns;

    // Finished Section
    if (_finishedDownloaders.isNotEmpty) {
      buffer.writeln("Finished ::");
      for (int i = 0; i < _finishedDownloaders.length; i++) {
        buffer.writeln("${i + 1}. ${_finishedDownloaders[i].filename}");
      }
      buffer.writeln("");
    }

    // Active Section
    final activeList = spawnedDownloaders.values
        .where((d) => !d.isCompleted && !d.isCancelled)
        .toList();

    if (activeList.isNotEmpty) {
      const boxWidth = 50;
      final showTwoColumns = width >= boxWidth * 2 + 4;

      for (int i = 0; i < activeList.length; i += (showTwoColumns ? 2 : 1)) {
        final d1 = activeList[i];
        final d2 = (showTwoColumns && i + 1 < activeList.length)
            ? activeList[i + 1]
            : null;

        final box1Lines = _generateBox(d1, i, boxWidth);
        final box2Lines = d2 != null ? _generateBox(d2, i + 1, boxWidth) : <String>[];

        final maxLines = math.max(box1Lines.length, box2Lines.length);

        for (int j = 0; j < maxLines; j++) {
          final l1 = j < box1Lines.length
              ? box1Lines[j].padRight(boxWidth)
              : "".padRight(boxWidth);
          if (d2 != null) {
            final l2 = j < box2Lines.length ? box2Lines[j] : "";
            buffer.writeln("$l1    $l2");
          } else {
            buffer.writeln(l1);
          }
        }
        buffer.writeln("");
      }
    }

    // Queue Section
    if (_queue.isNotEmpty) {
      buffer.writeln("Queue :: ${_queue.length} items");
    }

    _logBuffer.cleanLastLinesAndPrint(buffer.toString());
  }

  /// Generates the individual layout lines for a specific downloader box.
  List<String> _generateBox(Downloader d, int idx, int maxWidth) {
    final innerWidth = maxWidth - 4; // 2 for borders, 2 for padding

    String truncate(String text) {
      if (text.length <= innerWidth) return text.padRight(innerWidth);
      return "${text.substring(0, innerWidth - 3)}...".padRight(innerWidth);
    }

    final lines = <String>[];
    lines.add("-" * maxWidth);

    final streamType = d is MultiStreamDownload ? "Multi-Stream" : "Single-Stream";
    lines.add("| ${truncate('Downloader #${idx + 1} [$streamType] :: ${d.id}')} |");
    lines.add("| ${truncate('url:: ${d.url.toString()}')} |");
    lines.add("| ${truncate('')} |");

    final sizeText = d.isInitialising ? "Unknown" : d.status.sizeLeftText;
    lines.add("| ${truncate('Filename:: ${d.filename} ($sizeText)')} |");

    final speedText = d.isInitialising ? "0 KB/s" : d.status.speedText;
    lines.add("| ${truncate('Speed:: $speedText')} |");

    final etaText = d.isInitialising ? "N/A" : d.status.eta;
    lines.add("| ${truncate('Time:: $etaText')} |");
    lines.add("| ${truncate('')} |");

    if (!d.isInitialising) {
      final barLen = innerWidth - 25; // space for " 100% (10 MB/s)"
      final filled = ((d.status.progressPercent / 100) * barLen).round();
      final barChars = List.generate(barLen, (i) => i < filled ? '#' : '-').join();
      final pct = "${d.status.progressPercent.toStringAsFixed(0)}%".padLeft(4);
      final pLine = "[$barChars] $pct  ($speedText)";
      lines.add("| ${truncate(pLine)} |");
    } else {
      lines.add("| ${truncate('Initiating...')} |");
    }

    lines.add("| ${truncate('')} |");

    if (d is MultiStreamDownload) {
      lines.add("| ${truncate('Threads:')} |");
      final threadStatuses = d.workerStatuses.values.toList();

      for (int i = 0; i < threadStatuses.length; i += 2) {
        final t1 = threadStatuses[i];
        final t2 = (i + 1 < threadStatuses.length) ? threadStatuses[i + 1] : null;

        String formatThread(DownloadStatus ts) {
          const tBarLen = 8;
          final tFilled = ((ts.progressPercent / 100) * tBarLen).round();
          final tBarChars = List.generate(tBarLen, (j) => j < tFilled ? '#' : '-').join();
          final tPct = "${ts.progressPercent.toStringAsFixed(0)}%".padLeft(4);
          return "[$tBarChars] $tPct";
        }

        final str1 = formatThread(t1);
        final str2 = t2 != null ? formatThread(t2) : "";
        final combined = str2.isEmpty ? str1 : "$str1  $str2";

        lines.add("| ${truncate(combined)} |");
      }
    }

    lines.add("-" * maxWidth);
    return lines;
  }
}
