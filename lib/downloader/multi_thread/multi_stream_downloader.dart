// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// High-performance multi-threaded download implementation.
///
/// This library provides the [MultiStreamDownload] class, which utilizes multiple
/// concurrent HTTP connections and worker isolates to maximize download speeds.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:udm/downloader/downloader.dart';
import 'package:udm/downloader/models/messenger.dart';
import 'package:udm/downloader/models/worker_chunk.dart';
import 'package:udm/downloader/head_parser.dart';
import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/models/range.dart';

/// A downloader that splits a file into multiple chunks and fetches them concurrently.
///
/// [MultiStreamDownload] coordinates several worker isolates, each responsible
/// for a specific byte range of the file. It aggregates progress from all
/// workers to provide a unified [status] update.
///
/// **Usage**:
/// ```dart
/// final downloader = MultiStreamDownload(url: 'https://example.com/largefile.iso');
/// await downloader.start();
/// ```
class MultiStreamDownload extends Downloader {
  /// Creates a [MultiStreamDownload] instance for the given [url].
  MultiStreamDownload({required super.url, super.config}) {
    threadCounnt = config.threadCount ?? 8;
  }

  /// Number of concurrent worker threads to spawn.
  late final int threadCounnt;

  /// Active worker isolates indexed by their chunk ID.
  final WorkerMap<Isolate> _workers = {};

  /// Port for receiving messages from worker isolates.
  final ReceivePort _receivePort = ReceivePort();

  /// Byte ranges assigned to each worker.
  final List<Range> _workerRanges = [];

  /// Task configuration for each worker.
  final WorkerMap<WorkerChunk> _workerChunks = {};

  /// Progress monitors for each worker stream.
  final WorkerMap<DownloadStatus> _workerStatuses = {};

  /// Communication ports to send signals to workers.
  final WorkerMap<SendPort> _workerSendPorts = {};

  /// Set of worker indexes that have successfully completed their tasks.
  final Set<int> _finishedWorkerIndexes = {};

  /// Initializes worker ranges, chunks, and status trackers based on [threadCounnt].
  void _initWorkers() {
    _workerRanges.clear();
    _workerChunks.clear();
    _workerStatuses.clear();
    _workerSendPorts.clear();
    _finishedWorkerIndexes.clear();

    _workerRanges.addAll(fileSize.divideIntoParts(threadCounnt));

    for (int i = 0; i < threadCounnt; i++) {
      final range = _workerRanges[i];
      _workerChunks[i] = WorkerChunk(
        index: i,
        range: range,
        url: url,
        config: config,
        sendPort: _receivePort.sendPort,
      );
      _workerStatuses[i] = DownloadStatus(totalSize: range.size, id: i);
    }
  }

  @override
  Future<void> tryHeadRequest() async {
    headerInfo = await sendHeadRequest(url, null, logBuffer);
  }

  /// Routes and handles messages received from worker isolates.
  ///
  /// Processes progress updates, error reports, and connection handshakes.
  void _handleMessage(dynamic message) {
    final data = WorkerMessage.parseFromData(message);

    if (data is ProgressMessage) {
      final msg = data;
      final index = msg.index;

      try {
        _workerStatuses[index]!.updateFromStatus(msg.status);
        if (_workerStatuses[index]!.isCompleted) {
          _finishedWorkerIndexes.add(index);
        }
      } catch (e) {
        logBuffer.writeError("Error: $e");
      }
    } else if (data is ErrorMessage) {
      // TODO: Implement centralized error handling and retry orchestration
    } else if (data is HandshakeMessage) {
      final msg = data;
      final index = msg.index;
      final port = msg.sendPort;

      _workerSendPorts[index] = port;
    }
  }

  /// Subscribes to the internal [ReceivePort] to process worker messages.
  void startListeningOnRecievePort() {
    _receivePort.listen(_handleMessage);
  }

  @override
  Future<void> timerFunction(Timer timer) async {
    final statuses = _workerStatuses.values.toList();

    statuses.tickAll(timerInterval);

    int currentTotal = 0;
    for (var workerStatus in statuses) {
      currentTotal += workerStatus.totalBytesDownloaded;
    }

    status.totalBytesDownloaded = currentTotal;

    status.timerTick(timerInterval);

    if (stdout.hasTerminal) {
      if (status.isCompleted) {
        timer.cancel();
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
    _initWorkers();
    startListeningOnRecievePort();
    status.markStarted();

    for (int i = 0; i < threadCounnt; i++) {
      _workers[i] = await Isolate.spawn(downloadWorker, _workerChunks[i]!);
    }
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

  @override
  void showProgress() {
    if (isInitialising) return;

    final buffer = StringBuffer();

    // Line 1: Filename and Size
    buffer.writeln("File: $filename | (${status.sizeLeftText})");

    // The overall actual Progress Bar
    // Using status.showProgress() or makeProgressBar()
    buffer.writeln(status.makeProgressBar());

    if (_finishedWorkerIndexes.isNotEmpty) {
      buffer.writeln("Finished Threads: ${_finishedWorkerIndexes.toList()..sort()}");
    }

    if (!(_finishedWorkerIndexes.length == threadCounnt)) {
      buffer.writeln("\nThread Progresses::");

      for (var key in _workerStatuses.keys) {
        if (_finishedWorkerIndexes.contains(key)) continue;

        final workerStatus = _workerStatuses[key]!;
        buffer.writeln("Thread ${key + 1} | (${workerStatus.sizeLeftText})");
        buffer.writeln(workerStatus.makeProgressBar());
      }
    }

    // Line 3: Controls menu
    buffer.write("\nControls: [p] Pause | [r] Resume | [c] Cancel");

    final output = buffer.toString();
    logBuffer.cleanLastLinesAndPrint(output);
  }

  @override
  Future<void> cleanup() async {
    await super.cleanup();
    _receivePort.close();
    for (var worker in _workers.values) {
      worker.kill(priority: Isolate.immediate);
    }
    _workers.clear();
  }
}

/// Callback container for [ChunkDownloader] events.
class ChunkCallbacks {
  /// Executed when the chunk download progress is updated.
  late final void Function(DownloadStatus) onProgress;

  /// Executed when the chunk download completes successfully.
  late final void Function() onCompleted;

  /// Executed when a recoverable or fatal error occurs during chunk download.
  late final void Function(Object error, Range newRange) onError;

  /// Creates a [ChunkCallbacks] instance with the provided event handlers.
  ChunkCallbacks({
    required this.onProgress,
    required this.onCompleted,
    required this.onError,
  });
}

/// Orchestrates the download of a specific file range within a worker isolate.
///
/// [ChunkDownloader] handles the HTTP Range request, manages local file I/O
/// for the chunk, and implements retry logic with exponential backoff.
class ChunkDownloader {
  /// The task configuration for this chunk.
  final WorkerChunk worker;

  /// The HTTP client used for fetching data.
  final HttpClient client;

  /// Local progress tracker for this specific chunk.
  final DownloadStatus status;

  /// Event callbacks for reporting progress and errors back to the isolate controller.
  final ChunkCallbacks callbacks;

  /// Whether to automatically retry the download on network failures.
  final bool shouldRetryOnError;

  /// Maximum number of retry attempts before reporting a fatal error.
  final int maxRetryCount;

  /// Creates a [ChunkDownloader] instance.
  ChunkDownloader(
    this.worker,
    this.client,
    this.callbacks, {
    this.shouldRetryOnError = false,
    this.maxRetryCount = 2,
    DownloadStatus? status,
  }) : status = status ?? DownloadStatus(totalSize: worker.size, id: worker.index);

  /// Starts the chunk download process with retry logic.
  ///
  /// Performs an HTTP GET with a Range header, writes chunks to the resolved
  /// [RandomAccessFile], and triggers callbacks for progress and completion.
  ///
  /// Throws an exception if the server does not support partial content.
  Future<void> start() async {
    int attempts = 0;
    Range currentRange = worker.range;
    bool worthRetrying = true;

    while (attempts <= maxRetryCount) {
      RandomAccessFile? file;
      try {
        // Open in writeOnly mode to allow seeking to specific offsets
        file = await File(worker.config.absoluteFilename).open(mode: FileMode.writeOnly);

        status.markStarted();

        final request = await client.getUrl(worker.url);
        request.headers.add(HttpHeaders.rangeHeader, currentRange.asRangeHeader);
        final response = await request.close();

        if (response.statusCode != HttpStatus.partialContent) {
          worthRetrying = false;
          throw Exception(
            "Worker ${worker.index} failed: Server returned ${response.statusCode}, expected ${HttpStatus.partialContent}",
          );
        }

        // Seek to the correct start position for this attempt
        await file.setPosition(currentRange.start);

        await for (var chunk in response) {
          if (status.isPaused) {
            await status.waitUntilResume();
          }

          if (status.isCancelled) {
            throw Exception("Worker ${worker.index} was cancelled");
          }

          await file.writeFrom(chunk);
          status.increment(chunk.length);
          callbacks.onProgress(status);

          // Update currentRange.start so we resume from the exact byte if it fails next
          currentRange = Range(currentRange.start + chunk.length, currentRange.end);
        }

        status.markCompleted();
        callbacks.onCompleted();
        return; // Success
      } catch (e) {
        if (!shouldRetryOnError ||
            !worthRetrying ||
            attempts >= maxRetryCount ||
            status.isCancelled) {
          callbacks.onError(e, currentRange);
          return;
        }

        attempts++;
        final pauseTime = pow(2, attempts).toInt(); // Exponential backoff: 2s, 4s, ...
        await Future.delayed(Duration(seconds: pauseTime));
      } finally {
        await file?.close();
      }
    }
  }
}

/// The dedicated entry point for a worker isolate.
///
/// This function initializes the [WorkerMessenger], establishes a handshake with
/// the main isolate, and starts a [ChunkDownloader] to fetch the assigned byte range.
/// It offloads I/O and network operations to a separate thread to ensure main
/// isolate responsiveness.
Future<void> downloadWorker(WorkerChunk worker) async {
  final client = HttpClient();

  final DownloadStatus status = DownloadStatus(
    totalSize: worker.range.size,
    id: worker.index,
  );

  WorkerMessenger messenger = WorkerMessenger.fromSendPort(
    worker.sendPort,
    index: worker.index,
  );

  status.stream.listen((status) {
    messenger.sendProgressToMain(status);
  });

  messenger.onSignalIn = (message) {
    switch (message.signal) {
      case SignalType.pause:
        status.markPaused();
        break;
      case SignalType.resume:
        status.markResumed();
        break;
      case SignalType.cancel:
        status.markCancelled();
        break;
    }
  };

  messenger.startListening();
  messenger.handshake();

  // Periodic timer to calculate speed and trigger progress updates to main isolate
  final timer = Timer.periodic(const Duration(milliseconds: 500), (t) {
    status.timerTick(const Duration(milliseconds: 500));
  });

  final chunkDownloader = ChunkDownloader(
    worker,
    client,
    ChunkCallbacks(
      onProgress: (chunkStatus) {
        // No need to sync manually if we share the status object
      },
      onCompleted: () {
        // status is updated inside ChunkDownloader
      },
      onError: (error, newRange) {
        messenger.sendErrorToMain(newRange, error.toString());
      },
    ),
    status: status, // Share the status object to avoid sync issues
    shouldRetryOnError: true,
    maxRetryCount: 3,
  );

  // start the download
  try {
    await chunkDownloader.start();
  } catch (e) {
    // start() handles errors via callbacks, but catch for safety
  } finally {
    timer.cancel();
    client.close();
    await status.dispose();
  }
}
