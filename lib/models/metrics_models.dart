import 'dart:isolate';
import 'package:udm/helpers/extensions/int_extensions.dart';

export 'package:udm/head_parser.dart';

class ChunkMetrics {
  final DateTime chunkStartTime;
  final DateTime chunkEndTime;

  ChunkMetrics({required this.chunkStartTime, required this.chunkEndTime});
}

/// The chunk will be in isolate so we need to pass the configs as a single object.
class DownloadChunk {
  final int index;

  final Range range;

  /// the main url to download from
  final String url;

  /// the path where the chunk will be saved,
  /// the isolate must know this before making object make sure to pass path
  final String outputPath;

  final SendPort progressPort;

  /// if user has prefreed filename then we will use that else default to the filename from header info, or else "Udm-downloaded-file"
  final String filename;

  final Map<String, String> headers;

  const DownloadChunk({
    required this.index,
    required this.range,
    required this.url,
    required this.outputPath,
    required this.filename,
    required this.progressPort,
    this.headers = const {},
  });

  int get size => range.size;

  @override
  String toString() {
    return 'Chunk $index: bytes ${range.start}-${range.end} (size: ${size.asFileSize.humanReadable})';
  }
}
