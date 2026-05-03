import 'package:udm/helpers/extensions/map_extension.dart';

class Range {
  final int start;
  final int end;

  Range(this.start, this.end);
  int get size => end - start + 1;

  Map<String, int> toMap() => {"start": start, "end": end, "size": size};

  factory Range.fromMap(Map<String, int> map) {
    map.ensureKeyExists([
      "start",
      "end",
    ], "Cannot create a range from map because {{key}} is missing");
    return Range(map["start"]!, map["end"]!);
  }

  String get asRangeHeader => 'bytes=$start-$end';
}
