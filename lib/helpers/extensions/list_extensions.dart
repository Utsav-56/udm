// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Utility extensions for collections.
///
/// This library provides formatting and sorting helpers for [Set]s and [List]s,
/// primarily used for displaying worker thread statuses.
library;

extension SetExtensions on Set<int> {
  /// Returns a new [Set] containing the elements of this set in ascending order.
  Set<int> get sorted {
    final l = toList();
    l.sort();
    return l.toSet();
  }

  /// Returns a new [Set] where each element is incremented by 1 (1-indexed).
  Set<int> get incremental => sorted.map((e) => e + 1).toSet();

  /// Returns a comma-separated string of sorted, 1-indexed integers.
  ///
  /// Example: `{0, 2, 1}` -> `"1, 2, 3"`.
  String get sortedIncrementalString {
    final sortedList = toList()..sort();
    final incrementalList = sortedList.map((e) => e + 1).toList();

    return incrementalList.join(', ');
  }
}
