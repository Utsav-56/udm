import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:udm/downloader/downloader.dart';
import 'package:udm/downloader/multi_thread_helpers/messenger.dart';
import 'package:udm/head_parser.dart';
import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/models/downloader_config.dart';
import 'package:udm/models/metrics_models.dart';

/// The chunk will be in isolate so we need to pass the configs as a single object.
class WorkerChunk {
  final int index;

  final Range range;

  final DownloaderConfig config;

  final SendPort sendPort;

  const WorkerChunk({
    required this.index,
    required this.range,
    required this.config,
    required this.sendPort,
  });

  int get size => range.size;

  @override
  String toString() {
    return 'Chunk $index: bytes ${range.start}-${range.end} (size: ${size.asFileSize.humanReadable})';
  }
}

/// worker map always starts with index  as key
typedef WorkerMap<T> = Map<int, T>;

class MultiStreamDownload extends Downloader {
  MultiStreamDownload({required super.config});

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
        config: config,
        sendPort: _receivePort.sendPort,
      );
      _workerStatuses[i] = DownloadStatus(totalSize: range.size, id: i);
    }
  }

  @override
  Future<void> tryHeadRequest() async {
    headerInfo = await sendHeadRequest(config.url, null, logBuffer);
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

/// the download worker isolate entry point
Future<void> downloadWorker(WorkerChunk worker) async {
  final client = HttpClient();
  final file = await File(worker.config.absoluteFilename).open(mode: FileMode.append);

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

  // start the download
  try {
    status.markStarted();

    final request = await client.getUrl(worker.config.url);
    request.headers.add(HttpHeaders.rangeHeader, worker.range.asRangeHeader);
    final response = await request.close();

    if (response.statusCode != HttpStatus.partialContent) {
      throw Exception(
        "Worker ${worker.index} failed, Server might not support range headers or partial contents,  expected,  status of ${HttpStatus.partialContent} but got ${response.statusCode}",
      );
    }

    // seek to the correct start position for this thread
    await file.setPosition(worker.range.start);

    await for (var chunk in response) {
      if (status.isPaused) {
        await status.waitUntilResume();
      }

      if (status.isCancelled) {
        throw Exception("Worker ${worker.index} was cancelled");
      }

      await file.writeFrom(chunk);
      status.increment(chunk.length);

      messenger.sendProgressToMain(status);
    }

    status.markCompleted();
  } catch (e) {
    // in case of error we give the uncompleted rage
    final newRange = Range(
      worker.range.start + status.totalBytesDownloaded,
      worker.range.end,
    );
    messenger.sendErrorToMain(newRange, e.toString());
  } finally {
    await file.close();
    client.close();
    await status.dispose();
  }
}
