// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Data structures for defining worker-specific download tasks.
///
/// This library provides the [WorkerChunk] class, which encapsulates all
/// information required by a worker isolate to download a specific byte range.
library;

import 'dart:isolate';

import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/downloader/models/downloader_preference.dart';
import 'package:udm/models/range.dart';

/// Encapsulates the task parameters for a worker isolate.
///
/// [WorkerChunk] contains the unique identifier of the worker, the target
/// byte range, global configuration, and the communication port back to the
/// main isolate. This object is passed as the message when spawning a new isolate.
class WorkerChunk {
  /// The index of this chunk/worker in the download pool.
  final int index;

  /// The specific byte range assigned to this worker.
  final Range range;

  /// Global downloader configuration settings.
  final DownloaderPreference config;

  /// The port used to send progress and status updates to the main isolate.
  final SendPort sendPort;

  /// The source URL of the file.
  final Uri url;

  /// The absolute path to the local file.
  final String savePath;

  /// Creates a [WorkerChunk] with mandatory parameters.
  const WorkerChunk({
    required this.index,
    required this.range,
    required this.config,
    required this.url,
    required this.sendPort,
    required this.savePath,
  });

  /// Returns the size of the byte range in bytes.
  int get size => range.size;

  @override
  String toString() {
    return 'Chunk $index: bytes ${range.start}-${range.end} (size: ${size.asFileSize.humanReadable})';
  }

  /// Creates a copy of this [WorkerChunk] with optional updated fields.
  ///
  WorkerChunk copyWith({
    Range? newRange,
    int? index,
    DownloaderPreference? config,
    SendPort? sendPort,
    Uri? url,
    String? savePath,
  }) {
    return WorkerChunk(
      index: index ?? this.index,
      range: newRange ?? range,
      config: config ?? this.config,
      url: url ?? this.url,
      sendPort: sendPort ?? this.sendPort,
      savePath: savePath ?? this.savePath,
    );
  }
}

/// A type alias for maps where the key is the worker index.
typedef WorkerMap<T> = Map<int, T>;
