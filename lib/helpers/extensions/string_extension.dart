// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Utility extensions for [String] and [String?] to handle empty values.
///
/// This library provides simple getters to normalize empty strings into nulls,
/// simplifying conditional logic throughout the project.
library;

extension StringExtension on String {
  /// Returns `null` if the string is empty; otherwise returns the original string.
  String? get nullIfEmpty => isEmpty ? null : this;
}

extension StringExtensionNullable on String? {
  /// Returns `null` if the string is null or empty; otherwise returns the original string.
  String? get nullIfNullOrEmpty => (this == null || this!.isEmpty) ? null : this;
}
