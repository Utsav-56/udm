import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:udm/downloader/downloader.dart';
import 'package:udm/downloader/models/download_status.dart';
import 'package:udm/downloader/models/messenger.dart';
import 'package:udm/downloader/models/worker_chunk.dart';
import 'package:udm/downloader/head_parser.dart';
import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/models/range.dart';

/// Implementation of [Downloader] that uses multiple concurrent streams to fetch data.
///
/// **Why**: Significantly increases download speeds by bypassing single-connection limits
/// and utilizing the full available bandwidth across multiple TCP connections.
/// **How**: Spawns multiple isolates ([downloadWorker]) and coordinates their progress.
class MultiStreamDownload extends Downloader {
  MultiStreamDownload({required super.url, super.config});

  int threadCounnt = 8; // for now we hardcode this in future we use preference

  // to keep track of isolates so that we can kill them when needed
  final WorkerMap<Isolate> _workers = {};
  final ReceivePort _receivePort = ReceivePort();

  final List<Range> _workerRanges = [];
  final WorkerMap<WorkerChunk> _workerChunks = {};
  final WorkerMap<DownloadStatus> _workerStatuses = {};
  final WorkerMap<SendPort> _workerSendPorts = {};

  final Set<int> _finishedWorkerIndexes = {};

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

  // isolate only sends error message and progress message and a handshake
  void _handleMessage(dynamic message) {
    final data = WorkerMessage.parseFromData(message);

    if (data is ProgressMessage) {
      final msg = data as ProgressMessage;
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
    } else if (data is HandshakeMessage) {
      final msg = data as HandshakeMessage;
      final index = msg.index;
      final port = msg.sendPort;

      _workerSendPorts[index] = port;
    }
  }

  void startListeningOnRecievePort() {
    _receivePort.listen(_handleMessage);
  }

  @override
  Future<void> timerFunction(Timer timer) async {
    final _statuses = _workerStatuses.values.toList();

    _statuses.tickAll(timerInterval);

    int currentTotal = 0;
    for (var workerStatus in _statuses) {
      currentTotal += workerStatus.totalBytesDownloaded;
    }

    this.status.totalBytesDownloaded = currentTotal;

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

    buffer.writeln("Downloaded: $filename (${absolutePath})");
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

    if (!_finishedWorkerIndexes.isEmpty) {
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

class ChunkCallbacks {
  late final void Function(DownloadStatus) onProgress;
  late final void Function() onCompleted;
  late final void Function(Object error, Range newRange) onError;

  ChunkCallbacks({
    required this.onProgress,
    required this.onCompleted,
    required this.onError,
  });
}

/// Orchestrates the download of a specific file range.
///
/// **Why**: Encapsulates the logic for HTTP requests, file I/O, and retry mechanisms
/// for a single thread/chunk, keeping [MultiStreamDownload] focused on coordination.
/// **How**: Managed by a [downloadWorker] isolate.
class ChunkDownloader {
  final WorkerChunk worker;
  final HttpClient client;
  final DownloadStatus status;
  final ChunkCallbacks callbacks;

  final bool shouldRetryOnError;
  final int maxRetryCount;

  ChunkDownloader(
    this.worker,
    this.client,
    this.callbacks, {
    this.shouldRetryOnError = false,
    this.maxRetryCount = 2,
    DownloadStatus? status,
  }) : status = status ?? DownloadStatus(totalSize: worker.size, id: worker.index);

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

/// the download worker isolate entry point
/// The entry point for a dedicated download isolate.
///
/// **Why**: Offloads the computationally expensive network and file I/O operations
/// from the main UI/CLI thread to prevent interface lagging.
/// **How**: Spawned via [Isolate.spawn] with a [WorkerChunk] configuration.
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
