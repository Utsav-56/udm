import 'package:udm/models/downloader_config.dart';
import 'package:udm/models/metrics_models.dart';

class Range {
  final int start;
  final int end;

  Range(this.start, this.end);

  int get size => end - start + 1;

  @override
  String toString() => '$start-$end';

  String get headerValue => 'bytes=$start-$end';
}

extension DebugRange on List<Range> {
  void debug({int? expectedTotal}) {
    StringBuffer buffer = StringBuffer();

    if (expectedTotal != null) {
      /// the last end range is always the total so we dont need to calculate the total we can just get the end of the last range
      int total = this.isNotEmpty ? this.last.end : 0;

      buffer.writeln('Expected Total: ${expectedTotal} bytes');
      buffer.writeln('Calculated Total: ${total} bytes');
      buffer.writeln('Difference: ${total - expectedTotal} bytes\n');
    }

    for (int i = 0; i < this.length; i++) {
      buffer.writeln('Range ${i + 1}:');
      buffer.writeln('    Start: ${this[i].start}');
      buffer.writeln('    End: ${this[i].end}');
      buffer.writeln('    Size: ${this[i].size} bytes \n');
    }

    print("""
======================= Range Debug ================================
Total Ranges: ${this.length}


${buffer.toString()}
====================================================================

""");
    buffer.clear();
  }
}

extension IntExtensions on int {
  FileSize get asFileSize => FileSize(this);
  int get kb => this * 1024;
  int get mb => this * 1024 * 1024;
  int get gb => this * 1024 * 1024 * 1024;
  int get tb => this * 1024 * 1024 * 1024 * 1024;
  int get pb => this * 1024 * 1024 * 1024 * 1024 * 1024;

  /// equally divides the int into [parts] number of parts and returns the value of each part
  /// returns a list of ints where each int is the value of each part
  List<Range> divideIntoParts(int parts) {
    if (parts <= 0) {
      throw ArgumentError("Parts must be greater than 0");
    }

    final total = this;
    final partSize = total ~/ parts;
    final remainder = total % parts;

    int start = 0;

    return List.generate(parts, (i) {
      int size = partSize + (i == parts - 1 ? remainder : 0);
      int end = start + size - 1;

      final range = Range(start, end);
      start = end + 1;

      return range;
    });
  }
}
