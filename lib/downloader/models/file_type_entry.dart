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

import 'package:freezed_annotation/freezed_annotation.dart';

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

/// The default set of file type categories supported by UDM.
final List<FileTypeEntry> defaultFileTypes = [
  const FileTypeEntry(
    name: "Documents",
    extensions: {
      ".pdf",
      ".doc",
      ".docx",
      ".xls",
      ".xlsx",
      ".ppt",
      ".pptx",
      ".txt",
      ".rtf",
    },
    preferredSaveDir: "Documents",
  ),
  const FileTypeEntry(
    name: "Images",
    extensions: {".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".tiff", ".svg"},
    preferredSaveDir: "Images",
  ),
  const FileTypeEntry(
    name: "Videos",
    extensions: {".mp4", ".avi", ".mov", ".wmv", ".flv", ".mkv"},
    preferredSaveDir: "Videos",
  ),
  const FileTypeEntry(
    name: "Audio",
    extensions: {".mp3", ".wav", ".aac", ".flac", ".ogg", ".m4a"},
    preferredSaveDir: "Audio",
  ),
  const FileTypeEntry(
    name: "Archives",
    extensions: {".zip", ".rar", ".7z", ".tar", ".gz"},
    preferredSaveDir: "Archives",
  ),
];

/// A container for managing user-defined or default file type preferences.
class FileTypePreference {
  /// The list of file type categories.
  final List<FileTypeEntry> types;

  /// Creates a [FileTypePreference]. Defaults to [defaultFileTypes] if no types are provided.
  FileTypePreference({List<FileTypeEntry>? types})
      : types = types ?? defaultFileTypes;
}
