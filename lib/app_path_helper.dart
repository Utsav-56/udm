import 'dart:io';

import 'package:path/path.dart' as pth;

extension Helper on String {
  String? get nullIfEmpty => this.isEmpty ? null : this;
}

mixin pathHelper {
  void _handleError(Object e, String method) {
    print("Error in $method: $e");
    throw e;
  }

  // Path manipulations
  String join(String path1, String path2) => pth.join(path1, path2);
  bool equals(String path1, String path2) => pth.equals(path1, path2);
  String normalize(String path) => pth.normalize(path);
  String absolute(String path) => pth.absolute(path);
  String basename(String path) => pth.basename(path);
  String dirname(String path) => pth.dirname(path);
  String? extension(String? path) =>
      (path == null) ? null : pth.extension(path).nullIfEmpty;
  String withoutExtension(String path) => pth.withoutExtension(path);

  String? sanitizeFilename(String? name) {
    // Removes " / \ : * ? " < > | and hidden control characters
    return name == null
        ? null
        : name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '').trim();
  }

  bool mkDirAll(String path) {
    try {
      Directory(path).createSync(recursive: true);
      return true;
    } catch (e) {
      _handleError(e, "Path.mkDirAll");
      return false;
    }
  }

  Future<bool> mkDirAllAsync(String path) async {
    try {
      await Directory(path).create(recursive: true);
      return true;
    } catch (e) {
      _handleError(e, "Path.mkDirAllAsync");
      return false;
    }
  }

  /// Checks if the path exists and generates a unique name appending -<idx> until
  /// a unique name is found
  String? getUniqueName(String path) {
    try {
      if (!File(path).existsSync()) {
        return path;
      }

      final ext = pth.extension(path);
      final dir = pth.dirname(path);
      String base = pth.basenameWithoutExtension(path);

      final regex = RegExp(r'\((\d+)\)$');
      int idx = 1;

      // If already has (number), extract it
      final match = regex.firstMatch(base);
      if (match != null) {
        idx = int.parse(match.group(1)!) + 1;
        base = base.substring(0, match.start);
      }

      String newPath;
      do {
        newPath = pth.join(dir, "$base($idx)$ext");
        idx++;
      } while (File(newPath).existsSync());

      return newPath;
    } catch (e) {
      _handleError(e, "Path.getUniqueName");
      return null;
    }
  }

  String getFileExtension(String path) => pth.extension(path);

  bool isSameDir(String path1, String path2) =>
      pth.equals(path1, path2) || path1.startsWith(path2);
  bool isInsideSameDir(String path1, String path2) => path1.startsWith(path2);
  bool isSameFile(String path1, String path2) => pth.equals(path1, path2);

  // File finding/making helpers
  bool exists(String path) {
    try {
      return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
    } catch (e) {
      _handleError(e, "Path.exists");
      return false;
    }
  }

  Future<bool> existsAsync(String path) async {
    try {
      return (await FileSystemEntity.type(path) != FileSystemEntityType.notFound);
    } catch (e) {
      _handleError(e, "Path.existsAsync");
      return false;
    }
  }

  File? getFileIfExists(String path) {
    try {
      final f = File(path);
      return f.existsSync() ? f : null;
    } catch (e) {
      _handleError(e, "Path.getFileIfExists");
      return null;
    }
  }

  File? makeFileIfNotExist(String path) {
    try {
      final f = File(path);
      if (!f.existsSync()) f.createSync(recursive: true);
      return f;
    } catch (e) {
      _handleError(e, "Path.makeFileIfNotExist");
      return null;
    }
  }

  Future<File?> makeFileIfNotExistAsync(String path) async {
    try {
      final f = File(path);
      if (!await f.exists()) await f.create(recursive: true);
      return f;
    } catch (e) {
      _handleError(e, "Path.makeFileIfNotExistAsync");
      return null;
    }
  }

  // SYNC TOOLS

  bool copyFile(String source, String destination, {bool forceReplace = false}) {
    try {
      final file = File(source);
      final dest = getFileIfExists(destination);
      if (dest != null) {
        if (forceReplace) {
          dest.deleteSync();
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

  bool moveFile(String source, String destination, {bool forceReplace = false}) {
    try {
      final file = File(source);
      final dest = getFileIfExists(destination);
      if (dest != null) {
        if (forceReplace) {
          dest.deleteSync();
        } else {
          return false;
        }
      }
      file.renameSync(destination);
      return true;
    } catch (e) {
      _handleError(e, "Path.moveFile");
      return false;
    }
  }

  bool renameFile(String source, String destination, {bool forceReplace = false}) {
    return moveFile(source, destination, forceReplace: forceReplace);
  }

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

  String? getFileContents(String path) {
    try {
      final file = getFileIfExists(path);
      return file?.readAsStringSync();
    } catch (e) {
      _handleError(e, "Path.getFileContents");
      return null;
    }
  }

  bool writeFileContents(String path, String toWrite, {bool append = false}) {
    try {
      final file = makeFileIfNotExist(path);
      if (file == null) return false;
      file.writeAsStringSync(toWrite, mode: append ? FileMode.append : FileMode.write);
      return true;
    } catch (e) {
      _handleError(e, "Path.writeFileContents");
      return false;
    }
  }

  // ASYNC TOOLS

  Future<bool> copyFileAsync(
    String source,
    String destination, {
    bool forceReplace = false,
  }) async {
    try {
      final file = File(source);
      if (await file.exists()) {
        if (await existsAsync(destination)) {
          if (forceReplace) {
            await File(destination).delete();
          } else {
            return false;
          }
        }
        await file.copy(destination);
        return true;
      }
      return false;
    } catch (e) {
      _handleError(e, "Path.copyFileAsync");
      return false;
    }
  }

  Future<bool> moveFileAsync(
    String source,
    String destination, {
    bool forceReplace = false,
  }) async {
    try {
      final file = File(source);
      if (await file.exists()) {
        if (await existsAsync(destination)) {
          if (forceReplace) {
            await File(destination).delete();
          } else {
            return false;
          }
        }
        await file.rename(destination);
        return true;
      }
      return false;
    } catch (e) {
      _handleError(e, "Path.moveFileAsync");
      return false;
    }
  }

  Future<bool> renameFileAsync(
    String source,
    String destination, {
    bool forceReplace = false,
  }) async {
    return moveFileAsync(source, destination, forceReplace: forceReplace);
  }

  Future<bool> deleteFileAsync(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      _handleError(e, "Path.deleteFileAsync");
      return false;
    }
  }

  Future<String?> getFileContentsAsync(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      _handleError(e, "Path.getFileContentsAsync");
      return null;
    }
  }

  Future<bool> writeFileContentsAsync(
    String path,
    String toWrite, {
    bool append = false,
  }) async {
    try {
      final file = await makeFileIfNotExistAsync(path);
      if (file == null) return false;
      await file.writeAsString(toWrite, mode: append ? FileMode.append : FileMode.write);
      return true;
    } catch (e) {
      _handleError(e, "Path.writeFileContentsAsync");
      return false;
    }
  }

  // DIR HELPERS
  bool moveDir(String source, String destination) {
    try {
      Directory(source).renameSync(destination);
      return true;
    } catch (e) {
      _handleError(e, "Path.moveDir");
      return false;
    }
  }

  Future<bool> moveDirAsync(String source, String destination) async {
    try {
      await Directory(source).rename(destination);
      return true;
    } catch (e) {
      _handleError(e, "Path.moveDirAsync");
      return false;
    }
  }

  bool deleteDir(String path, {bool recursive = true}) {
    try {
      Directory(path).deleteSync(recursive: recursive);
      return true;
    } catch (e) {
      _handleError(e, "Path.deleteDir");
      return false;
    }
  }

  Future<bool> deleteDirAsync(String path, {bool recursive = true}) async {
    try {
      await Directory(path).delete(recursive: recursive);
      return true;
    } catch (e) {
      _handleError(e, "Path.deleteDirAsync");
      return false;
    }
  }

  bool isSymbolicLink(String path) {
    try {
      return FileSystemEntity.isLinkSync(path);
    } catch (e) {
      _handleError(e, "Path.isSymbolicLink");
      return false;
    }
  }

  Future<bool> isSymbolicLinkAsync(String path) async {
    try {
      return await FileSystemEntity.isLink(path);
    } catch (e) {
      _handleError(e, "Path.isSymbolicLinkAsync");
      return false;
    }
  }

  bool isDirectory(String path) {
    try {
      return Directory(path).existsSync();
    } catch (e) {
      _handleError(e, "Path.isDirectory");
      return false;
    }
  }

  Future<bool> isDirectoryAsync(String path) async {
    try {
      return await Directory(path).exists();
    } catch (e) {
      _handleError(e, "Path.isDirectoryAsync");
      return false;
    }
  }

  bool isFile(String path) {
    try {
      return File(path).existsSync();
    } catch (e) {
      _handleError(e, "Path.isFile");
      return false;
    }
  }

  Future<bool> isFileAsync(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      _handleError(e, "Path.isFileAsync");
      return false;
    }
  }

  String? resolveSymlinks(String path) {
    try {
      return File(path).resolveSymbolicLinksSync();
    } catch (e) {
      _handleError(e, "Path.resolveSymlinks");
      return null;
    }
  }

  Future<String?> resolveSymlinksAsync(String path) async {
    try {
      return await File(path).resolveSymbolicLinks();
    } catch (e) {
      _handleError(e, "Path.resolveSymlinksAsync");
      return null;
    }
  }
}

class AppPathHelper with pathHelper {
  AppPathHelper._privateConstructor();

  static final AppPathHelper to = AppPathHelper._privateConstructor();
}

/// A standard constant for path operations
/// no need to import path package with prefix p explicitly
final AppPathHelper p = AppPathHelper.to;
