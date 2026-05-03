// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Persistence framework for configuration and state objects.
///
/// This library provides interfaces and base classes for objects that can be
/// serialized to JSON and persisted to the local filesystem.
library;

import 'dart:convert';

import 'package:udm/helpers/path_helpers/path_helpers.dart';

/// Interface for objects that can be serialized to and from JSON.
///
/// [Savable] ensures that an object of type [T] can be converted to a [Map]
/// and reconstructed using a factory or reconstruction method.
abstract interface class Savable<T> {
  /// Converts the object into a JSON-compatible Map.
  Map<String, dynamic> toJson();

  /// Converts the object into a JSON-formatted string.
  String tojsonString() {
    return json.encode(toJson());
  }

  /// Reconstructs an object of type [T] from a JSON [Map].
  T fromJson(Map<String, dynamic> json);
}

/// Base class for managing persistent configurations.
///
/// [SaveableConfig] provides the logic for loading and saving a [Savable] object
/// [T] to a specific file path. It handles file existence checks and error
/// recovery by returning a [defaultValue] when necessary.
abstract class SaveableConfig<T extends Savable> {
  /// The absolute filesystem path where the configuration is stored.
  String get configFilePath;

  /// The fallback configuration used if no saved file exists or if loading fails.
  T get defaultValue;

  /// Loads and reconstructs the configuration from the [configFilePath].
  ///
  /// Returns [defaultValue] if the file does not exist or contains invalid data.
  T load() {
    if (!p.exists(configFilePath)) {
      return defaultValue;
    }

    final data = p.readAsString(configFilePath);
    if (data == null) {
      return defaultValue;
    }

    final parsedJson = json.decode(data);
    return defaultValue.fromJson(parsedJson);
  }

  /// Reads the raw JSON map from the saved configuration file.
  ///
  /// Returns an empty Map if the file does not exist or is unreadable.
  Map<String, dynamic> readSavedConfig() {
    try {
      if (!p.exists(configFilePath)) {
        return {};
      }

      final data = p.readAsString(configFilePath);
      if (data == null) {
        return {};
      }

      final parsedJson = json.decode(data);
      return parsedJson;
    } catch (e) {
      rethrow;
    }
  }

  /// Persists the given [config] to the [configFilePath].
  ///
  /// Creates the file and parent directories if they do not exist.
  void save(T config) {
    p.writeAsString(configFilePath, config.tojsonString());
  }
}
