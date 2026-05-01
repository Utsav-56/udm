import 'dart:isolate';
import 'package:udm/helpers/extensions/int_extensions.dart';

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

class FileSize {
  final int bytes;

  const FileSize(this.bytes);

  int get asKb => bytes ~/ 1024;
  int get asMb => bytes ~/ (1024 * 1024);
  int get asGb => bytes ~/ (1024 * 1024 * 1024);
  int get asTb => bytes ~/ (1024 * 1024 * 1024 * 1024);
  int get asPb => bytes ~/ (1024 * 1024 * 1024 * 1024 * 1024);

  String get humanReadable {
    if (bytes >= 1 << 30) {
      return '${(bytes / (1 << 30)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1 << 20) {
      return '${(bytes / (1 << 20)).toStringAsFixed(2)} MB';
    } else if (bytes >= 1 << 10) {
      return '${(bytes / (1 << 10)).toStringAsFixed(2)} KB';
    } else {
      return '$bytes bytes';
    }
  }
}
