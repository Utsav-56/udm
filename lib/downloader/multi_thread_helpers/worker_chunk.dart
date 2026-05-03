import 'dart:isolate';

import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/models/downloader_config.dart';

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

  /// copies all the metadata of this worker with the new range
  /// this is crucial when we want to retry the chunk or copy the current chhunk
  ///
  ///
  WorkerChunk copyWith({
    Range? newRange,
    int? index,
    DownloaderConfig? config,
    SendPort? sendPort,
  }) {
    return WorkerChunk(
      index: index ?? this.index,
      range: newRange ?? this.range,
      config: config ?? this.config,
      sendPort: sendPort ?? this.sendPort,
    );
  }
}

/// worker map always starts with index  as key
typedef WorkerMap<T> = Map<int, T>;
