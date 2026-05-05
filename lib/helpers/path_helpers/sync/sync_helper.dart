// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Synchronous filesystem utilities and path manipulation.
///
/// This library provides the [PathHelper] mixin, which encapsulates blocking
/// filesystem operations such as file creation, deletion, renaming, and metadata
/// retrieval. It also includes a comprehensive mapping of file extensions to
/// logical categories.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as pth;
import 'package:udm/helpers/extensions/string_extension.dart';

/// Map of file categories to their common extensions.
///
/// Used for categorizing downloads into "Documents", "Images", "Videos", etc.
const Map<String, List<String>> fileTypes = {
  "Documents": [
    ".pdf",
    ".doc",
    ".docx",
    ".xls",
    ".xlsx",
    ".ppt",
    ".pptx",
    ".txt",
    ".rtf",
    ".odt",
    ".ods",
    ".odp",
    ".csv",
  ],
  "Images": [
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".webp",
    ".bmp",
    ".tiff",
    ".svg",
    ".heic",
    ".avif",
  ],
  "Videos": [
    ".mp4",
    ".mkv",
    ".avi",
    ".mov",
    ".wmv",
    ".flv",
    ".webm",
    ".mpeg",
    ".mpg",
    ".3gp",
    ".ts",
  ],
  "Audio": [".mp3", ".aac", ".wav", ".flac", ".ogg", ".m4a", ".wma", ".opus", ".amr"],
  "Compressed": [".zip", ".rar", ".7z", ".tar", ".gz", ".bz2", ".xz", ".iso"],
  "Executable": [
    ".exe",
    ".msi",
    ".apk",
    ".dmg",
    ".deb",
    ".rpm",
    ".app",
    ".jar",
    ".sh",
    ".bat",
  ],
};

/// A mixin providing a comprehensive suite of synchronous filesystem operations.
///
/// [PathHelper] simplifies working with the [dart:io] and [path] packages by
/// providing a unified, high-level API for common tasks like joining paths,
/// checking existence, and performing file/directory CRUD operations.
mixin PathHelper {
  void _handleError(Object e, String method) {
    print("Error in $method: $e");
    throw e;
  }

  /// Joins up to six path parts into a single platform-specific path.
  ///
  /// Example: `join('home', 'user', 'downloads')` -> `'home/user/downloads'` (POSIX).
  String join(
    String part1, [
    String? part2,
    String? part3,
    String? part4,
    String? part5,
    String? part6,
  ]) {
    String res = part1;
    if (part2 != null) res = pth.join(res, part2);
    if (part3 != null) res = pth.join(res, part3);
    if (part4 != null) res = pth.join(res, part4);
    if (part5 != null) res = pth.join(res, part5);
    if (part6 != null) res = pth.join(res, part6);
    return res;
  }

  /// Joins path parts and returns the result ONLY if it exists on the filesystem.
  ///
  /// Returns `null` if the joined path does not exist.
  String? joinExisting(
    String path1, [
    String? part2,
    String? part3,
    String? part4,
    String? part5,
    String? part6,
  ]) {
    final joinedPath = join(path1, part2, part3, part4, part5, part6);
    if (exists(joinedPath)) {
      return joinedPath;
    }
    return null;
  }

  /// Checks if two paths are equal.
  bool equals(String path1, String path2) => pth.equals(path1, path2);

  /// Normalizes a path, simplifying redundant elements like `..` and `.`.
  String normalize(String path) => pth.normalize(path);

  /// Returns the absolute path for a given path.
  String absolute(String path) => pth.absolute(path);

  /// Returns the basename of the given path (the last part).
  String basename(String path) => pth.basename(path);

  /// Returns the directory name of the given path.
  String dirname(String path) => pth.dirname(path);

  /// Returns the extension of the given path.
  String? extension(String? path) =>
      (path == null) ? null : pth.extension(path).nullIfEmpty;

  /// Returns the path without its extension.
  String withoutExtension(String path) => pth.withoutExtension(path);

  /// Sanitizes a filename by removing illegal characters.
  String? sanitizeFilename(String? name) {
    // Removes " / \ : * ? " < > | and hidden control characters
    return name?.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '').trim();
  }

  /// Checks if the given path represents an existing file.
  bool isFile(String path) => FileSystemEntity.isFileSync(path);

  /// Checks if the given path represents an existing directory.
  bool isDirectory(String path) => FileSystemEntity.isDirectorySync(path);

  /// Checks if the given path represents a symbolic link.
  bool isLink(String path) => FileSystemEntity.isLinkSync(path);

  /// Checks if two paths refer to the same location.
  bool isSame(String path1, String path2) => pth.equals(path1, path2);

  /// Returns `true` if [path2] is a child or nested descendant of [path1].
  bool isInsideSameDir(String path1, String path2) {
    final p1 = pth.normalize(path1);
    final p2 = pth.normalize(path2);
    return pth.isWithin(p2, p1);
  }

  /// Checks if a file system entity exists at the given path.
  bool exists(String path) {
    try {
      return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
    } catch (e) {
      _handleError(e, "Path.exists");
      return false;
    }
  }

  /// Creates a directory and all its parent directories.
  ///
  /// Returns `true` if successful or if it already exists.
  bool mkDirAll(String path) {
    try {
      /// if path is not a valid dir then throw error
      final pathType = typeOf(path, followLinks: false);
      if (pathType == FileSystemEntityType.file ||
          pathType == FileSystemEntityType.link) {
        throw ArgumentError("Path cannot be a file or a link");
      }

      /// if path is a dir but not exists then create it
      if (pathType == FileSystemEntityType.notFound) {
        Directory(path).createSync(recursive: true);
      }
      return true;
    } catch (e) {
      _handleError(e, "Path.mkDirAll");
      return false;
    }
  }

  /// Categorizes a [filename] based on its extension into groups like "Images" or "Videos".
  ///
  /// Returns an empty string if the extension is unknown.
  String getFileType(String filename) {
    final ext = extension(filename);
    for (final type in fileTypes.entries) {
      if (type.value.contains(ext)) {
        return type.key;
      }
    }

    // if not found then return empty string.
    return "";
  }

  /// Returns the current user's home directory path.
  ///
  /// Resolves using `userprofile` (Windows) or `HOME` (POSIX) environment variables.
  String getHomeDir() =>
      Platform.environment['userprofile'] ?? Platform.environment['HOME'] ?? "";

  /// Returns the path to the user's Downloads directory.
  ///
  /// Handles platform-specific locations and respects the `XDG_DOWNLOAD_DIR`
  /// environment variable on Linux.
  String getDownloadDir() {
    String home = getHomeDir();
    // Linux: Check XDG standard first, then fallback
    return Platform.environment['XDG_DOWNLOAD_DIR'] ?? join(home, "Downloads");
  }

  /// Returns the path to the user's Documents directory.
  String getDocumentsDir() {
    String home = getHomeDir();

    return join(home, "Documents");
  }


  /// Returns the type of the file system entity at the given path.
  ///
  /// If [followLinks] is `true`, symbolic links will be followed.
  /// Returns [FileSystemEntityType.notFound] if it doesn't exist.
  FileSystemEntityType typeOf(String path, {bool followLinks = false}) =>
      FileSystemEntity.typeSync(path, followLinks: followLinks);

  /// Checks if the path exists and generates a unique name by appending `-(idx)`
  /// until a unique name is found.
  ///
  /// This function does not create the file or directory, it just generates a unique name.
  String getUniqueName(String path) {
    try {
      final typeOfPath = typeOf(path, followLinks: false);

      if (typeOfPath == FileSystemEntityType.notFound) {
        return path;
      }

      final dir = pth.dirname(path);
      String base;
      String ext = "";

      if (typeOfPath == FileSystemEntityType.directory) {
        base = pth.basename(path);
      } else {
        // file OR symlink → treat the same
        ext = pth.extension(path);
        base = pth.basenameWithoutExtension(path);
      }

      final regex = RegExp(r'\(\d+\)$');
      int idx = 1;

      final match = regex.firstMatch(base);
      if (match != null) {
        idx = int.parse(match.group(0)!.replaceAll('(', '').replaceAll(')', '')) + 1;
        base = base.substring(0, match.start);
      }

      String newPath;

      do {
        newPath = pth.join(dir, "$base($idx)$ext");
        idx++;
      } while (typeOf(newPath, followLinks: false) != FileSystemEntityType.notFound);

      return newPath;
    } catch (e) {
      _handleError(e, "Path.getUniqueName");
      rethrow;
    }
  }

  /// Returns the extension of the file at the given [path].
  String getFileExtension(String path) => pth.extension(path);

  // --- CRUD operations on files and directories ---

  /// Copies a file from [source] to [destination].
  ///
  /// If [forceReplace] is `true`, it will overwrite the destination file if it already exists.
  /// Returns `true` if the copy was successful, `false` otherwise.
  bool copyFile(String source, String destination, {bool forceReplace = false}) {
    try {
      final file = File(source);
      if (!file.existsSync()) {
        return false;
      }

      final destFile = File(destination);
      if (destFile.existsSync()) {
        if (forceReplace) {
          destFile.deleteSync();
        } else {
          return false;
        }
      }

      file.copySync(destination);
      return true;
    } catch (e) {
      _handleError(e, "Path.copyFile");
      return false;
    }
  }

  /// Copies a directory from [source] to [destination].
  ///
  /// If [forceReplace] is `true`, it will overwrite the destination directory if it already exists.
  /// Returns `true` if the copy was successful, `false` otherwise.
  bool copyDir(String source, String destination, {bool forceReplace = false}) {
    try {
      final dir = Directory(source);
      if (!dir.existsSync()) {
        return false;
      }

      if (pth.isWithin(source, destination)) {
        throw ArgumentError("Destination cannot be a subdirectory of source");
      }

      final destDir = Directory(destination);
      if (destDir.existsSync()) {
        if (forceReplace) {
          destDir.deleteSync(recursive: true);
        } else {
          return false;
        }
      }

      destDir.createSync(recursive: true);

      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        final relativePath = pth.relative(entity.path, from: source);
        final newPath = pth.join(destination, relativePath);

        if (entity is File) {
          final destFile = File(newPath);
          if (destFile.existsSync()) destFile.deleteSync();
          entity.copySync(newPath);
        } else if (entity is Directory) {
          Directory(newPath).createSync(recursive: true);
        } else if (entity is Link) {
          Link(newPath).createSync(entity.targetSync());
        }
      }

      return true;
    } catch (e) {
      _handleError(e, "Path.copyDir");
      return false;
    }
  }

  /// Moves a file from [source] to [destination].
  ///
  /// If [forceReplace] is `true`, it will overwrite the destination file if it already exists.
  /// Returns `true` if the move was successful, `false` otherwise.
  bool moveFile(String source, String destination, {bool forceReplace = false}) {
    try {
      final file = File(source);
      if (!file.existsSync()) {
        return false;
      }

      final destFile = File(destination);
      if (destFile.existsSync()) {
        if (forceReplace) {
          destFile.deleteSync();
        } else {
          return false;
        }
      }

      file.renameSync(destination);
      return true;
    } catch (e) {
      // Cross-device rename fallback
      return _copyAndDeleteFile(source, destination, forceReplace: forceReplace);
    }
  }

  /// Moves a directory from [source] to [destination].
  ///
  /// If [forceReplace] is `true`, it will overwrite the destination directory if it already exists.
  /// Returns `true` if the move was successful, `false` otherwise.
  bool moveDir(String source, String destination, {bool forceReplace = false}) {
    try {
      final dir = Directory(source);
      if (!dir.existsSync()) {
        return false;
      }

      if (pth.isWithin(source, destination)) {
        throw ArgumentError("Destination cannot be a subdirectory of source");
      }

      final destDir = Directory(destination);
      if (destDir.existsSync()) {
        if (forceReplace) {
          destDir.deleteSync(recursive: true);
        } else {
          return false;
        }
      }

      dir.renameSync(destination);
      return true;
    } catch (e) {
      // Cross-device rename fallback
      return _copyAndDeleteDir(source, destination, forceReplace: forceReplace);
    }
  }

  /// Fallback to copy and then delete a file for cross-device moves.
  bool _copyAndDeleteFile(
    String source,
    String destination, {
    bool forceReplace = false,
  }) {
    try {
      if (copyFile(source, destination, forceReplace: forceReplace)) {
        File(source).deleteSync();
        return true;
      }
      return false;
    } catch (e) {
      _handleError(e, "Path._copyAndDeleteFile");
      return false;
    }
  }

  /// Fallback to copy and then delete a directory for cross-device moves.
  bool _copyAndDeleteDir(String source, String destination, {bool forceReplace = false}) {
    try {
      if (copyDir(source, destination, forceReplace: forceReplace)) {
        Directory(source).deleteSync(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      _handleError(e, "Path._copyAndDeleteDir");
      return false;
    }
  }

  /// Deletes a file at the given [path].
  ///
  /// Returns `true` if the deletion was successful, `false` otherwise.
  bool deleteFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
        return true;
      }
      return false;
    } catch (e) {
      _handleError(e, "Path.deleteFile");
      return false;
    }
  }

  /// Deletes a directory at the given [path].
  ///
  /// If [recursive] is `true`, it deletes all nested files and directories.
  /// Returns `true` if the deletion was successful, `false` otherwise.
  bool deleteDir(String path, {bool recursive = false}) {
    try {
      final dir = Directory(path);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: recursive);
        return true;
      }
      return false;
    } catch (e) {
      _handleError(e, "Path.deleteDir");
      return false;
    }
  }

  // --- Link Helpers ---

  /// Creates a symbolic link at [path] pointing to [target].
  bool makeLink(String path, String target) {
    try {
      Link(path).createSync(target, recursive: true);
      return true;
    } catch (e) {
      _handleError(e, "Path.makeLink");
      return false;
    }
  }

  /// Resolves the target of a symbolic link.
  String? resolveLink(String path) {
    try {
      if (isLink(path)) {
        return Link(path).targetSync();
      }
      return null;
    } catch (e) {
      _handleError(e, "Path.resolveLink");
      return null;
    }
  }

  // --- Metadata & Info Helpers ---

  /// Returns the stats for the given path.
  FileStat getStat(String path) => FileStat.statSync(path);

  /// Returns the size of the file or directory in bytes.
  /// For directories, it calculates the total size recursively.
  int getSize(String path) {
    try {
      final entity = FileSystemEntity.typeSync(path);
      if (entity == FileSystemEntityType.file) {
        return File(path).lengthSync();
      } else if (entity == FileSystemEntityType.directory) {
        int totalSize = 0;
        for (final file in Directory(path).listSync(recursive: true)) {
          if (file is File) {
            totalSize += file.lengthSync();
          }
        }
        return totalSize;
      }
      return 0;
    } catch (e) {
      _handleError(e, "Path.getSize");
      return 0;
    }
  }

  /// Checks if a directory is empty.
  bool isEmpty(String path) {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) return true;
      return dir.listSync().isEmpty;
    } catch (e) {
      _handleError(e, "Path.isEmpty");
      return true;
    }
  }

  /// Clears all contents of a directory without deleting the directory itself.
  bool clearDir(String path) {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) return true;
      for (final entity in dir.listSync()) {
        entity.deleteSync(recursive: true);
      }
      return true;
    } catch (e) {
      _handleError(e, "Path.clearDir");
      return false;
    }
  }

  // --- Content Helpers ---

  /// Reads the entire file as bytes.
  Uint8List? readAsBytes(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return file.readAsBytesSync();
      }
      return null;
    } catch (e) {
      _handleError(e, "Path.readAsBytes");
      return null;
    }
  }

  /// Writes bytes to a file.
  bool writeAsBytes(String path, Uint8List bytes, {bool append = false}) {
    try {
      final file = File(path);
      if (!file.existsSync()) file.createSync(recursive: true);
      file.writeAsBytesSync(bytes, mode: append ? FileMode.append : FileMode.write);
      return true;
    } catch (e) {
      _handleError(e, "Path.writeAsBytes");
      return false;
    }
  }

  // --- Temp Helpers ---

  /// Creates a temporary directory.
  Directory createTempDir([String prefix = 'temp_']) {
    return Directory.systemTemp.createTempSync(prefix);
  }

  /// Creates a temporary file.
  File createTempFile([String prefix = 'temp_']) {
    final tempDir = Directory.systemTemp.createTempSync(prefix);
    return File(pth.join(tempDir.path, 'file.tmp'))..createSync();
  }

  /// Returns a list of entities in the directory at the given [path].
  ///
  /// If [recursive] is `true`, it lists all nested entities.
  /// If [followLinks] is `true`, it follows symbolic links.
  List<FileSystemEntity> list(
    String path, {
    bool recursive = false,
    bool followLinks = false,
  }) {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) return [];
      return dir.listSync(recursive: recursive, followLinks: followLinks);
    } catch (e) {
      _handleError(e, "Path.list");
      return [];
    }
  }

  /// Sets the last modified time of the file.
  bool setLastModified(String path, DateTime time) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.setLastModifiedSync(time);
        return true;
      }
      return false;
    } catch (e) {
      _handleError(e, "Path.setLastModified");
      return false;
    }
  }

  /// Reads the entire file as a list of lines.
  List<String>? readLines(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return file.readAsLinesSync();
      }
      return null;
    } catch (e) {
      _handleError(e, "Path.readLines");
      return null;
    }
  }

  /// Reads the entire contents of a file as a string.
  ///
  /// Returns `null` if the file does not exist or an error occurs.
  String? readAsString(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return file.readAsStringSync();
      }
      return null;
    } catch (e) {
      _handleError(e, "Path.readAsString");
      return null;
    }
  }

  /// Writes a string to a file.
  bool writeAsString(String path, String content, {bool append = false}) {
    try {
      final file = File(path);
      if (!file.existsSync()) file.createSync(recursive: true);
      file.writeAsStringSync(content, mode: append ? FileMode.append : FileMode.write);
      return true;
    } catch (e) {
      _handleError(e, "Path.writeAsString");
      return false;
    }
  }
}
