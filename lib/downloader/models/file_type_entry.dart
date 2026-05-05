// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Data structures for categorizing files by their extensions.
///
/// This library provides the [FileTypeEntry] model for defining file categories
/// and the [FileTypePreference] container for managing a collection of these categories.
library;

import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:udm/helpers/path_helpers/path_helpers.dart';

part 'file_type_entry.freezed.dart';
part 'file_type_entry.g.dart';

/// Represents a category of files grouped by their extensions.
///
/// Used by the [DownloadManager] to organize downloads into subdirectories
/// based on the file type (e.g., "Documents", "Videos").
@freezed
abstract class FileTypeEntry with _$FileTypeEntry {
  /// Creates a new [FileTypeEntry].
  ///
  /// - [name]: The display name of the category (e.g., "Videos").
  /// - [extensions]: A set of file extensions (including the dot) belonging to this category.
  /// - [preferredSaveDir]: The relative path within the main download directory where these files should be saved.
  const factory FileTypeEntry({
    required String name,
    required Set<String> extensions,
    required String preferredSaveDir,
  }) = _FileTypeEntry;

  /// Creates a [FileTypeEntry] from a JSON map.
  factory FileTypeEntry.fromJson(Map<String, dynamic> json) =>
      _$FileTypeEntryFromJson(json);
}

/// the filetypes of the current user preference
class FileTypePreference {
  final List<FileTypeEntry> types;

  /// this is a file read by defaul
  // each time the config is requested the file must be read so that we ensure we have latest change from file
  FileTypePreference({this.types = const []});

  /// Returns the path to the file types configuration file.
  static String get _filePath =>
      p.join(p.getHomeDir(), '.udm', 'config', 'file_types.json');

  factory FileTypePreference.fromFile() {
    final file = File(_filePath);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', _filePath);
    }

    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    final List<FileTypeEntry> types = (json["types"] as List<dynamic>)
        .map((e) => FileTypeEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    return FileTypePreference(types: types);
  }

  Map<String, dynamic> toJson() => {"types": types.map((e) => e.toJson()).toList()};

  bool typeExists(String type) {
    return types.any((element) => element.name == type);
  }

  bool extensionExists(String extension) =>
      types.any((element) => element.extensions.contains(extension));

  String? getType(String? extension) {
    if (extension == null) {
      return null;
    }

    for (var type in types) {
      if (type.extensions.contains(extension)) {
        return type.name;
      }
    }
    return null;
  }

  String? getPreferredSaveDirForType(String? type) {
    if (type == null) {
      return null;
    }
    for (var type in types) {
      if (type.name == type) {
        return type.preferredSaveDir;
      }
    }
    return null;
  }

  String? getPreferredSaveDirForExtension(String extension) {
    return getPreferredSaveDirForType(getType(extension));
  }

  void saveToFile() {
    final File file = File(_filePath);

    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }

    file.writeAsStringSync(const JsonEncoder.withIndent("  ").convert(toJson()));
  }
}
