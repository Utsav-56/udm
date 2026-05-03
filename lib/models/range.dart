// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Data model representing a byte range.
///
/// This library defines the [Range] class, used primarily for HTTP Range
/// requests and file segment management.
library;

import 'package:udm/helpers/extensions/map_extension.dart';

/// Represents a contiguous segment of data defined by [start] and [end] offsets.
class Range {
  /// The inclusive starting byte offset.
  final int start;

  /// The inclusive ending byte offset.
  final int end;

  /// Creates a [Range] from [start] to [end].
  Range(this.start, this.end);

  /// The total number of bytes in this range.
  int get size => end - start + 1;

  /// Serializes the range into a Map.
  Map<String, int> toMap() => {"start": start, "end": end, "size": size};

  /// Reconstructs a [Range] from a Map.
  ///
  /// Throws an [Exception] if mandatory keys are missing.
  factory Range.fromMap(Map<String, dynamic> map) {
    map.ensureKeyExists([
      "start",
      "end",
    ], "Cannot create a range from map because {{key}} is missing");
    return Range(map["start"]!, map["end"]!);
  }

  /// Returns the formatted string for the HTTP `Range` header.
  ///
  /// Example: `"bytes=0-1023"`.
  String get asRangeHeader => 'bytes=$start-$end';
}
