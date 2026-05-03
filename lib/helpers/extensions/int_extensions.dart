import 'package:udm/helpers/extensions/map_extension.dart';
import 'package:udm/downloader/models/downloader_config.dart';
import 'package:udm/models/file_size.dart';
import 'package:udm/models/range.dart';

extension IntExtensions on int {
  FileSize get asFileSize => FileSize(this);
  int get askb => this * 1024;
  int get asmb => this * 1024 * 1024;
  int get asgb => this * 1024 * 1024 * 1024;
  int get astb => this * 1024 * 1024 * 1024 * 1024;
  int get aspb => this * 1024 * 1024 * 1024 * 1024 * 1024;

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

extension ReadableSpeedHelper on num {
  String get humanReadableSpeed {
    if (this >= 1.asgb) {
      return "${(this / 1.asgb).toStringAsFixed(2)} GB/s";
    } else if (this >= 1.asmb) {
      return "${(this / 1.asmb).toStringAsFixed(2)} MB/s";
    } else if (this >= 1.askb) {
      return "${(this / 1.askb).toStringAsFixed(2)} KB/s";
    } else {
      return "${this.toStringAsFixed(2)} B/s";
    }
  }

  String get asSuitableSizeUnit {
    if (this >= 1.asgb) {
      return "${(this / 1.asgb).toStringAsFixed(2)} GB";
    } else if (this >= 1.asmb) {
      return "${(this / 1.asmb).toStringAsFixed(2)} MB";
    } else if (this >= 1.askb) {
      return "${(this / 1.askb).toStringAsFixed(2)} KB";
    } else {
      return "${this.toStringAsFixed(2)} B";
    }
  }

  /// gives a readable time unit such as "1s", "2m", "3h", "1d", "1w", "1mo", "1y"
  /// Assumes that the int is in seconds
  String get asReadableTimeUnit {
    final totalSeconds = this;

    if (totalSeconds <= 0) return "Done";

    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final parts = <String>[];

    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (seconds > 0) parts.add('${seconds}s');

    // limit to 2 most relevant units
    final result = parts.take(2).join(' ');

    return result.isEmpty ? "0s" : "$result left";
  }
}
