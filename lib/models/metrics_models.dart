import 'dart:isolate';
import 'package:udm/helpers/extensions/int_extensions.dart';

export 'package:udm/head_parser.dart';

/// Data model representing the timing metrics for an individual download chunk.
///
/// **Why**: This is essential for calculating thread-level performance and determining
/// if a specific chunk is lagging compared to others.
/// **How**: Instantiated within a worker isolate when a chunk starts and ends.
class ChunkMetrics {
  /// The timestamp when the chunk download was initiated.
  final DateTime chunkStartTime;

  /// The timestamp when the chunk download was completed.
  final DateTime chunkEndTime;

  /// Creates a new instance of [ChunkMetrics].
  ///
  /// **Note**: Ensure that [chunkEndTime] is after [chunkStartTime] for valid metric calculation.
  ChunkMetrics({required this.chunkStartTime, required this.chunkEndTime});
}
