extension Helper on Set<int> {
  Set<int> get sorted => {...this}..toList().sort();

  Set<int> get incremental => sorted.map((e) => e + 1).toSet();

  String get sortedIncrementalString {
    final sortedList = sorted.toList()..sort();
    final incrementalList = sortedList.map((e) => e + 1).toList();

    return incrementalList.join(', ');
  }
}
