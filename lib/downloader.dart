import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart';
import 'package:udm/app_path_helper.dart';
import 'package:udm/head_parser.dart';
import 'package:udm/helpers/extensions/date_extensions.dart';
import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/models/downloader.dart';

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

  Downloader({required this.config});

  StreamController<int> progressController = StreamController<int>.broadcast();
  Stream<int> get progressStream => progressController.stream;

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

  void _preInit() {
    metrics = config.verbose
        ? DownloaderMetrics.createVerbose()
        : DownloaderMetrics.create();
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
    _preInit();
    final client = HttpClient();

    metrics.logHeaderRequestStart();
    headerInfo = await sendHeadRequest(client, config.url);
    metrics.logHeaderRequestEnd();

    metrics.logFileAllocationStart();
    final raf = await makeFile();
    metrics.logFileAllocationEnd();

    if (headerInfo!.supportsMultiStream && config.downloadType != DownloadType.single) {
      final ranges = headerInfo!.fileSize.bytes.divideIntoParts(8);
    } else {
      await _downloadSingleStream(raf, client);
    }
  }

  /// We spawn in isolates so we cannot pass raf and client from our isolate we must create new in each isolate
  Future<void> _downloadMultiStream(List<Range> ranges) async {
    int theradCount = ranges.length;

    /// for now we will use 8 threads as default for prototype but in final we will allow to configure
    final ReceivePort receivePort = ReceivePort();

    receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
      } else if (message is String) {
        // This is a status message from a chunk
        print("Chunk Status: $message");
      }
    });

    for (int i = 0; i < theradCount; i++) {
      final chunk = DownloadChunk(
        index: i,
        startByte: ranges[i].start,
        endByte: ranges[i].end,
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
    metrics.logDownloadStart();

    final request = await client.getUrl(config.url);
    final response = await request.close();

    // Use writeOnly so we don't truncate the pre-allocated file

    int bytesReceived = 0;
    final totalSize = headerInfo!.fileSize.bytes;

    await for (var chunk in response) {
      await raf.writeFrom(chunk);
      bytesReceived += chunk.length;

      // Update progress
      double progress = (bytesReceived / totalSize) * 100;
      progressController.add(progress.toInt());
    }

    await raf.close();
    dispose();
  }

  void dispose() {
    metrics.logDownloadEnd();
    metrics.printSummary(this);
    progressController.close();
  }
}

class DownloadStatus {
  int totalBytesDownloaded = 0;
  int totalBytesToDownload;

  int downloadedLastSecond = 0;

  DownloadStatus({required this.totalBytesToDownload});

  void update(Map<String, dynamic> progressData) {
    int overallProgress = progressData["overallProgress"];

    totalBytesDownloaded = overallProgress;
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
    request.headers.set(
      HttpHeaders.rangeHeader,
      'bytes=${chunk.startByte}-${chunk.endByte}',
    );

    final response = await request.close();
    if (response.statusCode != HttpStatus.partialContent) {
      throw HttpException(
        'Server does not support range requests or returned an error. Status code: ${response.statusCode}',
      );
    }

    /// move the needle to the start byte of the chunk
    await file.setPosition(chunk.startByte);
    await for (var data in response) {
      await file.writeFrom(data);

      overallProgress += data.length;

      final progressData = {
        "chunkIndex": chunk.index,
        "overallProgress": overallProgress,
      };

      if (overallProgress > 0) {
        chunk.progressPort.send(progressData);
      }
    }

    /// if we reach here it means the chunk is downloaded successfully we can send a message to the main isolate to update the progress
    chunk.progressPort.send("Success: ${chunk.index}");
  } catch (e) {
    chunk.progressPort.send("Error: $e"); // Send the error message to the main isolate
  } finally {
    await file.close();
  }
}
