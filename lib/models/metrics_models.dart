import 'dart:isolate';
import 'package:udm/helpers/extensions/int_extensions.dart';

export 'package:udm/head_parser.dart';

class ChunkMetrics {
  final DateTime chunkStartTime;
  final DateTime chunkEndTime;

  ChunkMetrics({required this.chunkStartTime, required this.chunkEndTime});
}
