extension StringExtension on String {
  /// Returns a nullable string if the string is empty, otherwise returns the original string.
  String? get nullIfEmpty => this.isEmpty ? null : this;
}

extension StringExtensionNullable on String? {
  /// returns null if the string is null or empty, otherwise returns the original string.
  String? get nullIfNullOrEmpty => (this == null || this!.isEmpty) ? null : this;
}
