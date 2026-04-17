import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart';
import 'package:udm/app_path_helper.dart';
import 'package:udm/head_parser.dart';
import 'package:udm/helpers/extensions/date_extensions.dart';
import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/models/downloader.dart';

import 'helpers/extensions/list_extensions.dart';

/// for verbose mode to store each time and metrics
class DownloaderMetrics {
  DateTime? headerRequestStartTime;
  DateTime? headerRequestEndTime;

  DateTime? fileAllocationStartTime;
  DateTime? fileAllocationEndTime;

  DateTime? downloadStartTime;
  DateTime? downloadEndTime;

  final bool isVerbose;

  DownloaderMetrics({required this.isVerbose});

  factory DownloaderMetrics.create() => DownloaderMetrics(isVerbose: false);
  factory DownloaderMetrics.createVerbose() => DownloaderMetrics(isVerbose: true);

  void logHeaderRequestStart() {
    headerRequestStartTime = DateTime.now();
    if (isVerbose) {
      print("Header request started at: ${headerRequestStartTime!.formatted}");
    }
  }

  void logHeaderRequestEnd() {
    headerRequestEndTime = DateTime.now();
    if (isVerbose) {
      print("Header request ended at: ${headerRequestEndTime.formatted}");
      print(
        "Header request duration: ${headerRequestEndTime.readableDifference(headerRequestStartTime!)}",
      );
    }
  }

  void logFileAllocationStart() {
    fileAllocationStartTime = DateTime.now();
    if (isVerbose) {
      print("File allocation started at: ${fileAllocationStartTime!.formatted}");
    }
  }

  void logFileAllocationEnd() {
    fileAllocationEndTime = DateTime.now();
    if (isVerbose) {
      print("File allocation ended at: ${fileAllocationEndTime.formatted}");
      print(
        "File allocation duration: ${fileAllocationEndTime.readableDifference(fileAllocationStartTime!)}",
      );
    }
  }

  void logDownloadStart() {
    downloadStartTime = DateTime.now();
    if (isVerbose) {
      print("Download started at: ${downloadStartTime.formatted}");
    }
  }

  void logDownloadEnd() {
    downloadEndTime = DateTime.now();
    if (isVerbose) {
      print("Download ended at: ${downloadEndTime.formatted}");
      print(
        "Download duration: ${downloadEndTime.readableDifference(downloadStartTime)}",
      );
    }
  }

  void printSummary(Downloader downloader) {
    /// we dont care verbose mode or not we always log the summary at the end of the download
    print("""

\n=============================== Download Summary =================================
Filename: ${downloader.filenameToUse}
FilePath: ${downloader.outputPath}
File Size: ${downloader.headerInfo?.fileSize.humanReadable ?? "Unknown"}

Header Request:
  Start Time: ${headerRequestStartTime.formatted}
  End Time: ${headerRequestEndTime.formatted}
  Duration: ${headerRequestEndTime.readableDifference(headerRequestStartTime)}

File Allocation:
  Start Time: ${fileAllocationStartTime.formatted}
  End Time: ${fileAllocationEndTime.formatted}
  Duration: ${fileAllocationEndTime.readableDifference(fileAllocationStartTime)}

Download:
  Start Time: ${downloadStartTime.formatted}
  End Time: ${downloadEndTime.formatted}
  Duration: ${downloadEndTime.readableDifference(downloadStartTime)}
==================================================================================\n

""");
  }
}

class Downloader {
  final DownloaderConfig config;
  HeaderInfo? headerInfo;
  late final DownloaderMetrics metrics;

  Downloader({required this.config}) {
    metrics = config.verbose
        ? DownloaderMetrics.createVerbose()
        : DownloaderMetrics.create();
  }

  Timer? _progressTimer;
  bool _isMultiStream = false; // to keep track if multi or single

  /// this is to keep track of the overall download status for whole download
  DownloadStatus? overallStatus;

  String?
  _resolvedOutputPath; // This will hold the final output path after resolving filename and directory

  String get filenameToUse {
    String filename =
        config.preferredFilename ?? headerInfo?.filename ?? "UDM-DOWNLOADED-FILE";
    return "$filename${headerInfo?.fileExtension}";
  }

  String get outputPath {
    if (_resolvedOutputPath != null) {
      return _resolvedOutputPath!;
    }

    final outputDir = config.outputDir;
    _resolvedOutputPath = p.getUniqueName(
      p.join(outputDir, filenameToUse),
    )!; // we have ensured the checks in each point and if we still get null here then god belss me my god

    return _resolvedOutputPath!;
  }

  Future<RandomAccessFile?> _preInit([bool isMultithread = false]) async {
    overallStatus = DownloadStatus(totalSize: headerInfo?.fileSize.bytes ?? 0);

    final raf = await makeFile();

    /// in multi stream there is no use of returning the raf so we close it here but in single it is needed so we return it
    if (isMultithread) {
      await raf.close();
      _isMultiStream = true;
      return null;
    }

    return raf;
  }

  Future<RandomAccessFile> makeFile() async {
    final file = File(outputPath);
    await file.create(recursive: true);

    // Phase 2: Allocation
    final raf = await file.open(mode: FileMode.write);
    await raf.truncate(headerInfo!.fileSize.bytes); // Cleaner than writeByte

    return raf;
  }

  void startDownload() async {
    final client = HttpClient();

    metrics.logHeaderRequestStart();
    headerInfo = await sendHeadRequest(client, config.url);
    metrics.logHeaderRequestEnd();

    if (headerInfo!.supportsMultiStream && config.downloadType != DownloadType.single) {
      final ranges = headerInfo!.fileSize.bytes.divideIntoParts(8);
      _downloadMultiStream(ranges);
    } else {
      final raf = await _preInit(false);
      _downloadSingleStream(raf!, client);
    }
  }

  /// We spawn in isolates so we cannot pass raf and client from our isolate we must create new in each isolate
  /// for now we will use 8 threads as default for prototype but in final we will allow to configure
  Future<void> _downloadMultiStream(List<Range> ranges) async {
    await _preInit(true);
    int theradCount = ranges.length;

    final ReceivePort receivePort = ReceivePort();

    final statuses = List.generate(
      theradCount,
      (index) => DownloadStatus(totalSize: ranges[index].size),
    );

    final messages = List.generate(theradCount, (index) => WorkerMessage.initial(index));
    final successfulChunks =
        <int>{}; // to keep track of successful chunks for finalizing the file

    receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        int chunkIndex = message["chunkIndex"];
        final workerMessage = messages[chunkIndex].update(message);

        /// very first check if it is success or not;
        if (workerMessage.isSuccess) {
          successfulChunks.add(chunkIndex);
        } else if (workerMessage.isError) {
          print("Error in chunk ${chunkIndex + 1}: ${workerMessage.error}");
          return; // in future  retry will be added
        }

        /// if its  none of the above it is absolute progress update so we update the status of the chunk and overall progress
        statuses[chunkIndex].update(workerMessage.progressMap);
        int overallProgress = statuses.fold(
          0,
          (sum, status) => sum + status.totalBytesDownloaded,
        );
        overallStatus!.update({"overallProgress": overallProgress});
      }
    });

    /// prepare the timer before spawing isolate
    /// timer is supposed to track the progress
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      showProgress(statuses, successfulChunks);

      /// if all chunks are successful we can finalize the file and dispose the resources
      if (successfulChunks.length == theradCount) {
        dispose(receivePort);
      }
    });

    for (int i = 0; i < theradCount; i++) {
      final chunk = DownloadChunk(
        index: i,
        range: ranges[i],
        url: config.url.toString(),
        outputPath: outputPath,
        filename: filenameToUse,
        progressPort: receivePort.sendPort,
        metrics: metrics,
      );

      Isolate.spawn(downloadWorker, chunk);
    }
  }

  /// actually in single stream a same raf can be passed so we take that as param
  Future<void> _downloadSingleStream(RandomAccessFile raf, HttpClient client) async {
    _preInit(false);

    metrics.logDownloadStart();

    final request = await client.getUrl(config.url);
    final response = await request.close();

    // Use writeOnly so we don't truncate the pre-allocated file

    int bytesReceived = 0;
    final totalSize = headerInfo!.fileSize.bytes;

    /// init a timer for progress tracking
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      showProgress();
    });

    await for (var chunk in response) {
      await raf.writeFrom(chunk);
      bytesReceived += chunk.length;

      overallStatus!.update({"overallProgress": bytesReceived});
    }

    await raf.close();
    dispose();
  }

  /// A unified method to show progress for both single and multi stream downloads, it takes an optional parameter of list of chunk statuses which is used in multi stream download to show the progress of each chunk as well
  /// in case of single stream download the parameter will be null and it will just show the overall progress
  void showProgress([List<DownloadStatus>? statuses, Set<int>? successfulChunks]) {
    successfulChunks ??= {}; // initialize to empty set if null

    overallStatus!.timerTick();
    if (statuses != null) {
      for (var status in statuses) {
        status.timerTick(); // timer tick is harmless so i left as it is
      }
    }

    StringBuffer buffer = StringBuffer();

    // \x1B[2J = Clear screen, \x1B[0;0H = Move cursor to top-left
    stdout.write('\x1B[2J\x1B[0;0H');
    buffer.writeln(
      "\n\nFile: $filenameToUse | Size: ${headerInfo!.fileSize.humanReadable}",
    );

    buffer.writeln("${overallStatus!.makeProgressBar()}");

    if (statuses != null) {
      if (successfulChunks.isNotEmpty) {
        buffer.writeln("Finished Chunks: ${successfulChunks.sortedIncrementalString}");
      }

      buffer.writeln("\nChunk Progress:");

      for (int i = 0; i < statuses.length; i++) {
        if (successfulChunks.contains(i)) {
          continue;
        }

        buffer.writeln('Chunk ${i + 1}: \n${statuses[i].makeProgressBar()}');
      }
    } else {
      buffer.writeln(overallStatus!.makeProgressBar());
    }

    stdout.write(buffer.toString());
    buffer.clear();
  }

  void showFinalProgress() {
    stdout.write('\x1B[2J\x1B[0;0H');
    StringBuffer buffer = StringBuffer();

    buffer.writeln(
      "\n\n Download Complete! | File: $filenameToUse | Size: ${headerInfo!.fileSize.humanReadable} ",
    );
    buffer.writeln("Download Complete!");
    buffer.writeln(overallStatus!.makeProgressBar());

    stdout.write(buffer.toString());
    buffer.clear();
  }

  void dispose([ReceivePort? port]) {
    _progressTimer?.cancel();
    port?.close();
    metrics.logDownloadEnd();
    metrics.printSummary(this);
  }
}

extension ReadableSpeedHelper on num {
  String get humanReadableSpeed {
    if (this >= 1.gb) {
      return "${(this / 1.gb).toStringAsFixed(2)} GB/s";
    } else if (this >= 1.mb) {
      return "${(this / 1.mb).toStringAsFixed(2)} MB/s";
    } else if (this >= 1.kb) {
      return "${(this / 1.kb).toStringAsFixed(2)} KB/s";
    } else {
      return "${this.toStringAsFixed(2)} B/s";
    }
  }
}

class DownloadStatus {
  /// the overall progress of the download a chunk has finished so far
  int totalBytesDownloaded = 0;
  final int totalSize; // the final size a chunk is assigned to download

  int downloadedLastSecond = 0;
  int _previousBytesDownloaded = 0; // field needed for calculating speed in timer tick

  int get bytesLeft => totalSize - totalBytesDownloaded;
  double get progressPercent => (totalBytesDownloaded / totalSize) * 100;
  String get speed => downloadedLastSecond.humanReadableSpeed;

  String get eta {
    final speed = downloadedLastSecond;

    if (speed <= 0) return "Calculating...";

    final totalSeconds = (bytesLeft / speed).ceil();

    if (totalSeconds <= 0) return "Done";

    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final parts = <String>[];

    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (seconds > 0) parts.add('${seconds}s');

    // limit to 2 most relevant units
    final result = parts.take(2).join(' ');

    return result.isEmpty ? "0s" : "$result left";
  }

  DownloadStatus({required this.totalSize});

  void update(Map<String, dynamic> progressData) {
    int overallProgress = progressData["overallProgress"];
    totalBytesDownloaded = overallProgress;
  }

  /// this will be called by the parent timer so we can assume that this is called every second
  /// we wont put per status timer just a single timer in parent calls them
  void timerTick() {
    downloadedLastSecond = totalBytesDownloaded - _previousBytesDownloaded;
    _previousBytesDownloaded = totalBytesDownloaded;
  }

  /// makes a bar such as
  /// [██████----------] 30% | Speed: 500 KB/s | ETA: 1m 20s left
  String makeProgressBar({int? barLength}) {
    String suffix = "${progressPercent.toStringAsFixed(2)}% | Speed: $speed | ETA: $eta";
    final width = stdout.hasTerminal ? stdout.terminalColumns : 80;

    /// if width is less then the suffix
    /// in short if the terminal is too small we show suffix below the bar instead of right side
    if (width < suffix.length + 10) {
      barLength = width - 3; // 2 for the brackets [] and 1 for some padding
      suffix = "\n$suffix"; // move suffix to next line
    } else {
      barLength = (width - suffix.length - 3);
    }

    final filledLength = ((progressPercent / 100) * barLength).round();
    String bar = '█' * filledLength + '-' * (barLength - filledLength);

    return "[$bar] $suffix";
  }
}

typedef WorkerMap = Map<String, dynamic>;

class WorkerMessage {
  final int chunkIndex;

  WorkerMap? progressData;

  String? status;
  int? lastFilePosition;
  String? error;

  /// they will be used just in case of error to update the range for retrying the remaining part of the chunk
  int? newStartByte;
  int? newEndByte;

  WorkerMessage({
    required this.chunkIndex,
    required this.progressData,
    this.status,
    this.lastFilePosition,
    this.error,
    this.newStartByte,
    this.newEndByte,
  });

  bool get isSuccess => status == "complete";
  bool get isError => status == "error";
  bool get isProgressUpdate => status == "progress";

  WorkerMap get progressMap => (isProgressUpdate || isSuccess)
      ? progressData!
      : {"chunkIndex": chunkIndex, "status": status ?? "unknown"};

  WorkerMap get errorMap => {
    "chunkIndex": chunkIndex,
    "status": status,
    "lastFilePosition": lastFilePosition,
    "error": error,
  };

  Range? get newRange => isError
      ? Range(newStartByte!, newEndByte!)
      : null; // we cannot and should not create if there is no error

  // we dont need success map because it only has index

  /// updates the current state with new message data
  /// we will store this in the main isolate to keep track of the status of each chunk and overall progress
  /// index is immutable as it is assigned at the time of creation
  WorkerMessage update(WorkerMap newMessage) {
    progressData = newMessage;
    status = newMessage["status"];
    lastFilePosition = newMessage["lastFilePosition"];
    error = newMessage["error"];
    newStartByte = newMessage["newStartByte"];
    newEndByte = newMessage["newEndByte"];

    return this;
  }

  /// this is the initial version of the message where only the index is set all other are null
  factory WorkerMessage.initial(int chunkIndex) {
    return WorkerMessage(
      chunkIndex: chunkIndex,
      progressData: {"chunkIndex": chunkIndex, "status": "initial"},
    );
  }
}

/// Isolate methods must not be wrapped in any class so we make it top level
void downloadWorker(DownloadChunk chunk) async {
  final client = HttpClient();
  final file = await File(chunk.outputPath).open(mode: FileMode.append);

  /// the local progress of the chunk download which will be sent to the main isolate to update the overall progress
  /// indicates the no of bytes downloaded in this chunk so far
  /// in case of error we will add this in the start value and make new start value to retry the remaining bytes
  int overallProgress = 0;

  try {
    final request = await client.getUrl(Uri.parse(chunk.url));
    request.headers.set(HttpHeaders.rangeHeader, chunk.range.headerValue);

    final response = await request.close();
    if (response.statusCode != HttpStatus.partialContent) {
      throw HttpException(
        'Server does not support range requests or returned an error. Status code: ${response.statusCode}',
      );
    }

    /// move the needle to the start byte of the chunk
    await file.setPosition(chunk.range.start);
    await for (var data in response) {
      await file.writeFrom(data);

      overallProgress += data.length;

      final progressData = {
        "status": "progress",
        "chunkIndex": chunk.index,
        "overallProgress": overallProgress,
        "totalSize": chunk.size,
      };

      if (overallProgress > 0) {
        chunk.progressPort.send(progressData);
      }
    }

    /// if we reach here it means the chunk is downloaded successfully we can send a message to the main isolate to update the progress
    chunk.progressPort.send({
      "chunkIndex": chunk.index,
      "status": "complete",
      "overallProgress": overallProgress,
      "totalSize": chunk.size,
    });
  } catch (e) {
    chunk.progressPort.send({
      "chunkIndex": chunk.index,
      "status": "error",
      "lastFilePosition": await file
          .position(), // so that we can retry from this position in case of error

      "newStartByte":
          chunk.range.start +
          overallProgress, // the new start byte for retrying the remaining part of the chunk
      "newEndByte": chunk.range.end, // the end byte remains the same

      "error": e.toString(),
    }); // Send the error message to the main isolate
  } finally {
    await file.close();
  }
}
