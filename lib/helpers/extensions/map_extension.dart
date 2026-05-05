// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Utility extensions for [Map] validation.
///
/// This library provides methods to verify the presence of mandatory keys
/// in configuration or state maps.
library;

extension MapExtension on Map<String, dynamic> {
  /// Validates that all specified [keys] are present in this map.
  ///
  /// If a key is missing, throws an [Exception] with the provided [message].
  /// The [message] can include `{{key}}` as a placeholder for the missing key.
  void ensureKeyExists(
    List<String> keys, [
    String message = "Mandatory key '{{key}}' is missing from the map",
  ]) {
    for (var key in keys) {
      if (!containsKey(key)) {
        final formattedMessage = message.replaceAll("{{key}}", key);
        throw Exception(formattedMessage);
      }
    }
  }
}

extension IterableHelper<T> on Iterable<T> {
  Map<int, T> toIndexedMap() {
    final map = <int, T>{};
    for (var i = 0; i < length; i++) {
      map[i] = elementAt(i);
    }
    return map;
  }
}
