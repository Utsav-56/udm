// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Utility for representing and formatting file sizes.
///
/// This library provides the [FileSize] class, which handles conversion between
/// raw bytes and human-readable units (KB, MB, GB, etc.).
library;

/// A container for byte values with built-in unit conversion and formatting.
class FileSize {
  /// The raw value in bytes.
  final int bytes;

  /// Creates a [FileSize] instance with the given number of [bytes].
  const FileSize(this.bytes);

  /// Returns the size in Kilobytes (integer division).
  int get asKb => bytes ~/ 1024;

  /// Returns the size in Megabytes (integer division).
  int get asMb => bytes ~/ (1024 * 1024);

  /// Returns the size in Gigabytes (integer division).
  int get asGb => bytes ~/ (1024 * 1024 * 1024);

  /// Returns the size in Terabytes (integer division).
  int get asTb => bytes ~/ (1024 * 1024 * 1024 * 1024);

  /// Returns the size in Petabytes (integer division).
  int get asPb => bytes ~/ (1024 * 1024 * 1024 * 1024 * 1024);

  /// Returns a human-readable string representation of the file size.
  ///
  /// Automatically selects the most appropriate unit (B, KB, MB, GB).
  /// Example: `1.50 MB`, `500 bytes`.
  String get humanReadable {
    if (bytes < 0) return "unknown size";

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
