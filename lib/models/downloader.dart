import 'dart:io';
import 'dart:isolate';

import 'package:udm/app_path_helper.dart';
import 'package:udm/downloader.dart';
import 'package:udm/helpers/extensions/int_extensions.dart';

enum DownloadType {
  /// forces the downloader to use single stream download
  /// even if the server supports range requests. This is useful for testing and for servers that have issues with range requests.
  single,

  /// allows the downloader to choose the best download method based on the server's capabilities.
  /// if server supports then we will use multi stream download, otherwise we will fall back to single stream download.
  /// it is the default download type and is recommended for most use cases
  smart,
}

class DownloaderConfig {
  late final Uri url;
  late final String outputDir;
  final String? preferredFilename;
  final bool verbose;
  final DownloadType downloadType;

  DownloaderConfig({
    required String fileUrl,
    String? saveDir,
    this.preferredFilename,
    this.verbose = false,
    this.downloadType = DownloadType.smart,
  }) {
    if (fileUrl.isEmpty) {
      throw ArgumentError("URL cannot be empty");
    }
    url = Uri.parse(fileUrl);

    if (saveDir != null && saveDir.isEmpty) {
      throw ArgumentError("Save directory cannot be empty");
    }

    /// check if the output dir is actually a dir path or a file path, if it's a file path then throw error
    if (saveDir != null) {
      final outputDirFile = FileSystemEntity.typeSync(saveDir);
      if (outputDirFile == FileSystemEntityType.file) {
        throw ArgumentError("Save directory cannot be a file path");
      }

      // if the output dir doesn't exist then create it
      if (outputDirFile == FileSystemEntityType.notFound) {
        Directory(saveDir).createSync(recursive: true);
      }

      outputDir = Directory(saveDir).absolute.path;
      return;
    }

    /// if no save dir is provided then we will use the systems default Download dir or the current directory as fallback
    final String? homeDir =
        Platform.environment['USERPROFILE'] ??
        Platform.environment['USER'] ??
        Platform.environment['HOME'];

    Directory downloadDir;

    if (homeDir != null) {
      downloadDir = Directory(p.join(homeDir, "Downloads"));
    } else {
      downloadDir = Directory.current;
    }

    if (!downloadDir.existsSync()) {
      downloadDir.createSync(recursive: true);
    }

    outputDir = downloadDir.absolute.path;
  }
}

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
