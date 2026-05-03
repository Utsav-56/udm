import 'dart:convert';

import 'package:udm/helpers/path_helpers/path_helpers.dart';

/// Interface for all the savable objects
///
/// the type T will be the type of the object that will be saved
abstract interface class Savable<T> {
  Map<String, dynamic> toJson();
  String tojsonString() {
    return json.encode(toJson());
  }

  T fromJson(Map<String, dynamic> json);
}

/// Base class for all the saveable configurations
///
/// the type T will be the type of the config
///
/// it saves the config into a json format
/// the T must  implement the [Savable] interface with method of [toJson] and [fromJson]
/// the [toJson] will be used to save the config
/// the [fromJson] will be used to load the config
abstract class SaveableConfig<T extends Savable> {
  /// the path to the file where the config will be saved
  /// this should be the full path and absolute is recommended
  String get configFilePath;

  /// a default config must  always be provided in case there is no config file found
  ///
  /// if config is found then the found config is returned
  ///
  T get defaultValue;

  /// this is the default implementation of the load method
  /// it will load the config from the file
  /// it will use the [fromJson] method to load the config
  /// if the file is not found then it will return the default config
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

  /// this is the default implementation of the save method
  /// it will save the config to the file
  /// it will use the [toJson] method to save the config
  /// if the file is not found then it will create the file
  void save(T config) {
    p.writeAsString(configFilePath, config.tojsonString());
  }
}
