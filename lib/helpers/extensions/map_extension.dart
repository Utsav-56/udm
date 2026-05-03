extension MapExtension on Map<String, dynamic> {
  void ensureKeyExists(
    List<String> keys, [
    String message = "Key {{key}} does not exist",
  ]) {
    for (var key in keys) {
      if (!containsKey(key)) {
        message = message.replaceAll("{{key}}", key);
        throw Exception(message);
      }
    }
  }
}
