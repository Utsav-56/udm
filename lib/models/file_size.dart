/// Utility class for representing and formatting file sizes.
///
/// **Why**: Simplifies conversion between bytes, KB, MB, and GB while providing
/// a consistent human-readable string representation.
class FileSize {
  final int bytes;

  const FileSize(this.bytes);

  int get asKb => bytes ~/ 1024;
  int get asMb => bytes ~/ (1024 * 1024);
  int get asGb => bytes ~/ (1024 * 1024 * 1024);
  int get asTb => bytes ~/ (1024 * 1024 * 1024 * 1024);
  int get asPb => bytes ~/ (1024 * 1024 * 1024 * 1024 * 1024);

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
