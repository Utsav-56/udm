import 'dart:io';
import 'dart:isolate';

import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/path_helpers/path_helpers.dart';

/// Download type specifies what method of download the downloader should use
///
/// It can either be single or smart download.
///
/// We cannot always ensure that multi stream is possible so, there is no multi stream only type
enum DownloadType {
  /// forces the downloader to use single stream download
  /// even if the server supports range requests. This is useful for testing and for servers that have issues with range requests.
  single,

  /// allows the downloader to choose the best download method based on the server's capabilities.
  /// if server supports then we will use multi stream download, otherwise we will fall back to single stream download.
  /// it is the default download type and is recommended for most use cases
  smart,
}

/// The config needed for downloader to download the file.
/// It includes all the configs or that the downloader needs to set before starting the download
class DownloaderConfig {
  /// the url of the file to be downloaded
  ///
  /// it is required and cannot be empty
  late final Uri url;

  /// the directory where the downloaded file will be saved
  /// If not provided then it will use the default download directory of the system or the current directory as fallback
  ///
  /// it is optional but if provided then, ensure that the path is valid and you actually have write prrmisisons in that directory,
  /// otherwise it will throw an error when the downloader tries to save the file
  late final String outputDir;

  /// the preferred filename that you want to use for the saved file,
  /// it is purely optional
  /// if not provided then we will try to get the filename from header info, url respectively, or else we will default to "Udm-downloaded-file"
  ///
  /// If provided and the filename already exists then a unique suffix will automatically be added to the filename to avoid the overwritting issue of existing file
  ///
  final String? preferredFilename;

  /// This is for debugging purpose,
  /// if it is verbose then it will print the logs of the download process in the terminals std io, otherwise it will not print any logs
  /// it is purely optional and  defaults to false
  ///
  /// this will just print the logs in terminal,
  /// but if the process is not attached to a terminal then no matter if user gives verbose or not it will be false in that case.
  final bool verbose;

  /// the [DownloadType] that the downloader will use to download the file, it is optional and defaults to [DownloadType.smart]
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
