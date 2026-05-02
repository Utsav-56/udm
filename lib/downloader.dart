// import 'dart:async';
// import 'dart:io';
// import 'dart:isolate';

// import 'package:udm/head_parser.dart';
// import 'package:udm/helpers/extensions/int_extensions.dart';
// import 'package:udm/helpers/terminal_helpers/terminal_helper.dart';
// import 'package:udm/models/downloader_config.dart';
// import 'package:udm/models/metrics_models.dart';
// import 'package:udm/helpers/path_helpers/path_helpers.dart';
// import 'helpers/extensions/list_extensions.dart';

// /// This value will be sent to the downloader to pause the download
// const int downloadPauseSignal = 0;

// /// This value will be sent to the downloader to cancel the download
// const int downloadCancelSignal = -1;

// /// This value will be sent to the downloader to resume the download
// const int downloadResumeSignal = 1;

// class __Downloader {
//   final DownloaderConfig config;
//   HeaderInfo? headerInfo;

//   Downloader({required this.config});

//   Timer? _progressTimer;
//   bool _isFinished = false;
//   StreamSubscription?
//   _inputSubscription; // to listen for user input for pause/resume/cancel commands

//   bool _isPaused =
//       false; // to track the paused state of the download, this is used in single stream download

//   bool get isPaused => _isPaused;

//   /// this is to keep track of the overall download status for whole download
//   DownloadStatus? overallStatus;

//   String?
//   _resolvedOutputPath; // This will hold the final output path after resolving filename and directory

//   String get filenameToUse {
//     String filename =
//         config.preferredFilename ?? headerInfo?.filename ?? "UDM-DOWNLOADED-FILE";
//     return "$filename${headerInfo?.fileExtension}";
//   }

//   String get outputPath {
//     if (_resolvedOutputPath != null) {
//       return _resolvedOutputPath!;
//     }

//     final outputDir = config.outputDir;
//     _resolvedOutputPath = p.getUniqueName(
//       p.join(outputDir, filenameToUse),
//     )!; // we have ensured the checks in each point and if we still get null here then god belss me my god

//     return _resolvedOutputPath!;
//   }

//   Future<RandomAccessFile?> _preInit([bool isMultithread = false]) async {
//     overallStatus = DownloadStatus(totalSize: headerInfo?.fileSize.bytes ?? 0);

//     println("Preparing file for download at: $outputPath", 2);
//     final raf = await makeFile();
//     println("File prepared successfully.");

//     /// in multi stream there is no use of returning the raf so we close it here but in single it is needed so we return it
//     if (isMultithread) {
//       await raf.close();
//       return null;
//     }

//     return raf;
//   }

//   Future<RandomAccessFile> makeFile() async {
//     final file = File(outputPath);
//     await file.create(recursive: true);

//     // Phase 2: Allocation
//     final raf = await file.open(mode: FileMode.write);
//     await raf.truncate(headerInfo!.fileSize.bytes); // Cleaner than writeByte

//     return raf;
//   }

//   void startDownload() async {
//     /// we keep this in print to clean later
//     print("Starting download for: ${config.url}");
//     final client = HttpClient();
//     println("Sending HEAD request to fetch file info...");

//     headerInfo = await sendHeadRequest(client, config.url);
//     println("Received file info:\n$headerInfo", 2);

//     if (headerInfo!.supportsMultiStream && config.downloadType != DownloadType.single) {
//       println(
//         "Server supports multi-stream download. Starting multi-threaded download...",
//       );
//       final ranges = headerInfo!.fileSize.bytes.divideIntoParts(8);
//       _downloadMultiStream(ranges);
//     } else {
//       final raf = await _preInit(false);

//       println(
//         "Server does not support multi-stream download or single stream download is forced. Starting single-threaded download...",
//       );

//       _downloadSingleStream(raf!, client);
//     }
//   }

//   /// We spawn in isolates so we cannot pass raf and client from our isolate we must create new in each isolate
//   /// for now we will use 8 threads as default for prototype but in final we will allow to configure
//   Future<void> _downloadMultiStream(List<Range> ranges) async {
//     await _preInit(true);
//     int theradCount = ranges.length;

//     final ReceivePort receivePort = ReceivePort();

//     final statuses = List.generate(
//       theradCount,
//       (index) => DownloadStatus(totalSize: ranges[index].size),
//     );

//     final messages = List.generate(theradCount, (index) => WorkerMessage.initial(index));
//     final successfulChunks =
//         <int>{}; // to keep track of successful chunks for finalizing the file

//     final List<Isolate> isolates =
//         []; // to keep track of isolates so we can kill them if needed

//     int readyWorkers =
//         0; // to track how many workers are ready before starting the timer and accepting commands
//     final Map<int, SendPort> commandPorts = {};

//     TerminalHelper.clearScreen();
//     TerminalHelper.enableRawMode();

//     _inputSubscription = stdin.listen((data) {
//       final acceptableCommands = ['p', 'r', 'c'];

//       for (var byte in data) {
//         final char = String.fromCharCode(byte).toLowerCase();

//         if (acceptableCommands.contains(char)) {
//           if (readyWorkers < theradCount) {
//             println(
//               "Workers are not ready yet. Please wait until all workers are ready to accept commands.",
//             );
//             return;
//           }
//         }

//         switch (char) {
//           case 'p':
//             for (var port in commandPorts.values) {
//               port.send("pause");
//             }
//             _isPaused = true;
//             break;

//           case 'r':
//             for (var port in commandPorts.values) {
//               port.send("resume");
//             }
//             _isPaused = false;
//             break;

//           case 'c':
//             for (var port in commandPorts.values) {
//               port.send("cancel");
//             }
//             TerminalHelper.disableRawMode();
//             dispose(receivePort);
//             print("\nDownload cancelled by user.");
//             exit(0);
//         }
//       }
//     });

//     receivePort.listen((message) {
//       if (message is Map<String, dynamic>) {
//         int chunkIndex = message["chunkIndex"];
//         final workerMessage = messages[chunkIndex].update(message);

//         if (workerMessage.isInitial) {
//           commandPorts[chunkIndex] = message["commandPort"];
//           readyWorkers++;
//           return; // we dont need to do anything else for initial message
//         }

//         /// very first check if it is success or not;
//         if (workerMessage.isSuccess) {
//           successfulChunks.add(chunkIndex);
//         } else if (workerMessage.isError) {
//           print("Error in chunk ${chunkIndex + 1}: ${workerMessage.error}");
//           return; // in future  retry will be added
//         }

//         /// if its  none of the above it is absolute progress update so we update the status of the chunk and overall progress
//         statuses[chunkIndex].update(workerMessage.progressMap);
//         int overallProgress = statuses.fold(
//           0,
//           (sum, status) => sum + status.totalBytesDownloaded,
//         );
//         overallStatus!.update({"overallProgress": overallProgress});
//         return;
//       }
//     });

//     /// prepare the timer before spawing isolate
//     /// timer is supposed to track the progress
//     _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
//       if (readyWorkers < theradCount) {
//         println(
//           "Only $readyWorkers/${theradCount} workers are ready. Waiting for all workers to be ready before showing progress...",
//         );
//         return;
//       }

//       if (_isFinished) return;

//       showProgress(statuses, successfulChunks);

//       /// if all chunks are successful we can finalize the file and dispose the resources
//       if (successfulChunks.length == theradCount) {
//         _isFinished = true;
//         timer.cancel();
//         showFinalProgress();
//         dispose(receivePort);
//       }
//     });

//     for (int i = 0; i < theradCount; i++) {
//       final chunk = DownloadChunk(
//         index: i,
//         range: ranges[i],
//         url: config.url.toString(),
//         outputPath: outputPath,
//         filename: filenameToUse,
//         progressPort: receivePort.sendPort,
//       );

//       final isolate = await Isolate.spawn(downloadWorker, chunk);
//       isolates.add(isolate);
//     }
//   }

//   /// actually in single stream a same raf can be passed so we take that as param
//   /// pre init is already done before calling so we wont repeat here
//   Future<void> _downloadSingleStream(RandomAccessFile raf, HttpClient client) async {
//     final request = await client.getUrl(config.url);
//     final response = await request.close();

//     int bytesReceived = 0;
//     final totalSize = headerInfo!.fileSize.bytes;

//     /// init a timer for progress tracking
//     _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
//       showProgress();
//     });

//     await for (var chunk in response) {
//       await raf.writeFrom(chunk);
//       bytesReceived += chunk.length;

//       overallStatus!.update({"overallProgress": bytesReceived});
//     }

//     await raf.close();
//     dispose();
//   }

//   void cancelDownload([ReceivePort? receivePort]) {
//     TerminalHelper.disableRawMode();
//     dispose(receivePort);

//     /// also delete the file because it is incomplete and we dont want to leave junk files
//     if (_resolvedOutputPath != null) {
//       final file = File(_resolvedOutputPath!);
//       if (file.existsSync()) {
//         file.deleteSync();
//       }
//     }

//     print("\nDownload cancelled by user.");
//     exit(0);
//   }

  // /// A unified method to show progress for both single and multi stream downloads, it takes an optional parameter of list of chunk statuses which is used in multi stream download to show the progress of each chunk as well
  // /// in case of single stream download the parameter will be null and it will just show the overall progress
  // void showProgress([List<DownloadStatus>? statuses, Set<int>? successfulChunks]) {
  //   successfulChunks ??= {}; // initialize to empty set if null

  //   overallStatus!.timerTick();

  //   if (statuses != null) {
  //     for (var status in statuses) {
  //       status.timerTick(); // timer tick is harmless so i left as it is
  //     }
  //   }

  //   StringBuffer buffer = StringBuffer();

  //   // \x1B[2J = Clear screen, \x1B[0;0H = Move cursor to top-left
  //   stdout.write('\x1B[2J\x1B[0;0H');
  //   buffer.writeln(
  //     "\n\nFile: $filenameToUse | (${overallStatus!.totalBytesDownloaded.asFileSize.humanReadable} / ${headerInfo!.fileSize.humanReadable} Downloaded) ",
  //   );

  //   buffer.writeln("${overallStatus!.makeProgressBar(isPaused: _isPaused)}");

  //   if (statuses != null) {
  //     if (successfulChunks.isNotEmpty) {
  //       buffer.writeln("Finished Chunks: ${successfulChunks.sortedIncrementalString}");
  //     }

  //     buffer.writeln("\nChunk Progress:");

  //     for (int i = 0; i < statuses.length; i++) {
  //       if (successfulChunks.contains(i)) {
  //         continue;
  //       }

  //       buffer.writeln(
  //         'Chunk ${i + 1}: \n${statuses[i].makeProgressBar(isPaused: _isPaused)}',
  //       );
  //     }
  //   }

  //   /// the keys helper menu
  //   buffer.writeln("\n\nControls: \n p: Pause \n r: Resume \n c: Cancel");

  //   stdout.write(buffer.toString());
  //   buffer.clear();
  // }

  // void showFinalProgress() {
  //   stdout.write('\x1B[2J\x1B[0;0H');
  //   StringBuffer buffer = StringBuffer();

  //   buffer.writeln("\n\n Download Complete! :: ");
  //   buffer.writeln("    File: $filenameToUse (${_resolvedOutputPath}) ");
  //   buffer.writeln("    Size: ${headerInfo!.fileSize.humanReadable} ");
  //   // buffer.writeln("Download Complete!");
  //   // buffer.writeln(overallStatus!.makeProgressBar());

  //   stdout.write(buffer.toString());
  //   buffer.clear();
  // }

//   void dispose([ReceivePort? port]) {
//     _progressTimer?.cancel();
//     port?.close();
//     _inputSubscription?.cancel();
//   }
// }

// typedef WorkerMap = Map<String, dynamic>;

// class WorkerMessage {
//   final int chunkIndex;

//   WorkerMap? progressData;

//   String? status;
//   int? lastFilePosition;
//   String? error;

//   /// they will be used just in case of error to update the range for retrying the remaining part of the chunk
//   int? newStartByte;
//   int? newEndByte;

//   /// in case of init
//   SendPort? commandPort;

//   WorkerMessage({
//     required this.chunkIndex,
//     required this.progressData,
//     this.status,
//     this.lastFilePosition,
//     this.error,
//     this.newStartByte,
//     this.newEndByte,
//   });

//   bool get isInitial => status == "initial";
//   bool get isSuccess => status == "complete";
//   bool get isError => status == "error";
//   bool get isProgressUpdate => status == "progress";

//   WorkerMap get progressMap => (isProgressUpdate || isSuccess)
//       ? progressData!
//       : {"chunkIndex": chunkIndex, "status": status ?? "unknown"};

//   WorkerMap get errorMap => {
//     "chunkIndex": chunkIndex,
//     "status": status,
//     "lastFilePosition": lastFilePosition,
//     "error": error,
//   };

//   Range? get newRange => isError
//       ? Range(newStartByte!, newEndByte!)
//       : null; // we cannot and should not create if there is no error

//   // we dont need success map because it only has index

//   /// updates the current state with new message data
//   /// we will store this in the main isolate to keep track of the status of each chunk and overall progress
//   /// index is immutable as it is assigned at the time of creation
//   WorkerMessage update(WorkerMap newMessage) {
//     progressData = newMessage;
//     status = newMessage["status"];
//     lastFilePosition = newMessage["lastFilePosition"];
//     error = newMessage["error"];
//     newStartByte = newMessage["newStartByte"];
//     newEndByte = newMessage["newEndByte"];

//     return this;
//   }

//   /// this is the initial version of the message where only the index is set all other are null
//   factory WorkerMessage.initial(int chunkIndex) {
//     return WorkerMessage(
//       chunkIndex: chunkIndex,
//       progressData: {"chunkIndex": chunkIndex, "status": "initial"},
//     );
//   }
// }

// /// Isolate methods must not be wrapped in any class so we make it top level
// void downloadWorker(DownloadChunk chunk) async {
//   final client = HttpClient();
//   final file = await File(chunk.outputPath).open(mode: FileMode.append);

//   bool isPaused = false; // This will track the paused state of the worker
//   bool isCancelled = false; // This will track the cancelled state of the worker

//   final ReceivePort commandPort = ReceivePort();
//   commandPort.listen((message) {
//     // Here you can handle commands from the main isolate, such as pause, resume, or cancel
//     // For example:
//     if (message == "pause") {
//       isPaused = true;
//     } else if (message == "resume") {
//       isPaused = false;
//     } else if (message == "cancel") {
//       isCancelled = true;
//       commandPort.close();
//     }
//   });

//   chunk.progressPort.send({
//     "chunkIndex": chunk.index,
//     "status": "initial",
//     "commandPort": commandPort.sendPort,
//   }); // Send the command port to the main isolate so it can send commands to this worker

//   /// the local progress of the chunk download which will be sent to the main isolate to update the overall progress
//   /// indicates the no of bytes downloaded in this chunk so far
//   /// in case of error we will add this in the start value and make new start value to retry the remaining bytes
//   int overallProgress = 0;

//   try {
//     final request = await client.getUrl(Uri.parse(chunk.url));
//     request.headers.set(HttpHeaders.rangeHeader, chunk.range.headerValue);

//     final response = await request.close();
//     if (response.statusCode != HttpStatus.partialContent) {
//       throw HttpException(
//         'Server does not support range requests or returned an error. Status code: ${response.statusCode}',
//       );
//     }

//     /// move the needle to the start byte of the chunk
//     await file.setPosition(chunk.range.start);
//     await for (var data in response) {
//       /// do infinite buffering if paused
//       /// we can adjust this delay as needed, this is just to prevent busy waiting
//       while (isPaused) {
//         await Future.delayed(const Duration(milliseconds: 300));

//         /// throwing exception is the best because catch will auto find the remaining part of chunk
//         /// also the final cleanup of file will happen, so this is better then returning and leaving the file open and resources hanging
//         if (isCancelled) {
//           throw Exception("Download cancelled");
//         }
//       }

//       await file.writeFrom(data);

//       overallProgress += data.length;

//       final progressData = {
//         "status": "progress",
//         "chunkIndex": chunk.index,
//         "overallProgress": overallProgress,
//         "totalSize": chunk.size,
//       };

//       if (overallProgress > 0) {
//         chunk.progressPort.send(progressData);
//       }
//     }

//     /// if we reach here it means the chunk is downloaded successfully we can send a message to the main isolate to update the progress
//     chunk.progressPort.send({
//       "chunkIndex": chunk.index,
//       "status": "complete",
//       "overallProgress": overallProgress,
//       "totalSize": chunk.size,
//     });
//   } catch (e) {
//     chunk.progressPort.send({
//       "chunkIndex": chunk.index,
//       "status": "error",
//       "lastFilePosition": await file
//           .position(), // so that we can retry from this position in case of error

//       "newStartByte":
//           chunk.range.start +
//           overallProgress, // the new start byte for retrying the remaining part of the chunk
//       "newEndByte": chunk.range.end, // the end byte remains the same

//       "error": e.toString(),
//     }); // Send the error message to the main isolate
//   } finally {
//     await file.close();
//   }
// }
