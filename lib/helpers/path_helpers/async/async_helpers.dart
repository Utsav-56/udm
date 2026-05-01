import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as pth;

/// A mixin containing asynchronous file system path manipulation and operations.
///
/// These methods are asynchronous counterparts to [PathHelper] methods.
mixin PathHelperAsync {
  void _handleError(Object e, String method) {
    print("Error in $method: $e");
    throw e;
  }

  /// Creates a directory and all its parent directories asynchronously.
  ///
  /// Returns `true` if successful, or if the directory already exists.
  /// Returns `false` if an error occurs.
  Future<bool> mkDirAllAsync(String path) async {
    try {
      await Directory(path).create(recursive: true);
      return true;
    } catch (e) {
      _handleError(e, "Path.mkDirAllAsync");
      return false;
    }
  }

  /// Copies a file from [source] to [destination] asynchronously.
  ///
  /// If [forceReplace] is `true`, it will overwrite the destination file if it already exists.
  /// Returns `true` if the copy was successful, `false` otherwise.
  Future<bool> copyFileAsync(
    String source,
    String destination, {
    bool forceReplace = false,
  }) async {
    try {
      final file = File(source);
      if (await file.exists()) {
        final destFile = File(destination);
        if (await destFile.exists()) {
          if (forceReplace) {
            await destFile.delete();
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

  /// Checks if the path exists asynchronously.
  ///
  /// Returns `true` if a file, directory, or link exists at the given path.
  Future<bool> existsAsync(String path) async {
    try {
      return (await FileSystemEntity.type(path) != FileSystemEntityType.notFound);
    } catch (e) {
      _handleError(e, "Path.existsAsync");
      return false;
    }
  }

  /// Moves a file from [source] to [destination] asynchronously.
  ///
  /// If [forceReplace] is `true`, it will overwrite the destination file if it already exists.
  /// Returns `true` if the move was successful, `false` otherwise.
  Future<bool> moveFileAsync(
    String source,
    String destination, {
    bool forceReplace = false,
  }) async {
    try {
      final file = File(source);
      if (await file.exists()) {
        final destFile = File(destination);
        if (await destFile.exists()) {
          if (forceReplace) {
            await destFile.delete();
          } else {
            return false;
          }
        }
        await file.rename(destination);
        return true;
      }
      return false;
    } catch (e) {
      // Fallback for cross device move error
      return await _copyAndDeleteFileAsync(
        source,
        destination,
        forceReplace: forceReplace,
      );
    }
  }

  /// Renames a file from [source] to [destination] asynchronously.
  ///
  /// This is an alias for [moveFileAsync].
  Future<bool> renameFileAsync(
    String source,
    String destination, {
    bool forceReplace = false,
  }) async {
    return moveFileAsync(source, destination, forceReplace: forceReplace);
  }

  /// Deletes a file at the given [path] asynchronously.
  ///
  /// Returns `true` if the deletion was successful, `false` otherwise.
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

  /// Reads and returns the contents of a file as a string asynchronously.
  ///
  /// Returns `null` if the file does not exist or an error occurs.
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

  /// Writes [toWrite] string contents to a file at [path] asynchronously.
  ///
  /// If [append] is `true`, it appends the content to the existing file.
  /// Returns `true` if the write was successful, `false` otherwise.
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

  /// Moves a directory from [source] to [destination] asynchronously.
  ///
  /// Returns `true` if the move was successful, `false` otherwise.
  Future<bool> moveDirAsync(
    String source,
    String destination, {
    bool forceReplace = false,
  }) async {
    try {
      final dir = Directory(source);
      if (!await dir.exists()) {
        return false;
      }

      if (pth.isWithin(source, destination)) {
        throw ArgumentError("Destination cannot be a subdirectory of source");
      }

      final destDir = Directory(destination);
      if (await destDir.exists()) {
        if (forceReplace) {
          await destDir.delete(recursive: true);
        } else {
          return false;
        }
      }

      await dir.rename(destination);
      return true;
    } catch (e) {
      // Fallback in case of cross-device rename failure
      return await _copyAndDeleteDirAsync(
        source,
        destination,
        forceReplace: forceReplace,
      );
    }
  }

  /// Deletes a directory at the given [path] asynchronously.
  ///
  /// If [recursive] is `true`, it deletes all nested files and directories.
  /// Returns `true` if the deletion was successful, `false` otherwise.
  Future<bool> deleteDirAsync(String path, {bool recursive = true}) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: recursive);
        return true;
      }
      return false;
    } catch (e) {
      _handleError(e, "Path.deleteDirAsync");
      return false;
    }
  }

  /// Checks if the entity at the given [path] is a symbolic link asynchronously.
  ///
  /// Returns `true` if it is a symbolic link, `false` otherwise.
  Future<bool> isSymbolicLinkAsync(String path) async {
    try {
      return await FileSystemEntity.isLink(path);
    } catch (e) {
      _handleError(e, "Path.isSymbolicLinkAsync");
      return false;
    }
  }

  /// Checks if the given [path] represents a directory asynchronously.
  ///
  /// Returns `true` if it is a directory, `false` otherwise.
  Future<bool> isDirectoryAsync(String path) async {
    try {
      return await Directory(path).exists();
    } catch (e) {
      _handleError(e, "Path.isDirectoryAsync");
      return false;
    }
  }

  /// Checks if the given [path] represents a file asynchronously.
  ///
  /// Returns `true` if it is a file, `false` otherwise.
  Future<bool> isFileAsync(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      _handleError(e, "Path.isFileAsync");
      return false;
    }
  }

  /// Resolves the symbolic link at the given [path] asynchronously.
  ///
  /// Returns the resolved path or `null` if an error occurs.
  Future<String?> resolveSymlinksAsync(String path) async {
    try {
      return await File(path).resolveSymbolicLinks();
    } catch (e) {
      _handleError(e, "Path.resolveSymlinksAsync");
      return null;
    }
  }

  /// Creates a file if it does not already exist asynchronously.
  ///
  /// Returns the [File] object if successful, or `null` if an error occurs.
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

  /// Returns the type of the file system entity at the given path asynchronously.
  ///
  /// If [followLinks] is true, symbolic links will be followed.
  Future<FileSystemEntityType> typeOfAsync(
    String path, {
    bool followLinks = false,
  }) async {
    try {
      return await FileSystemEntity.type(path, followLinks: followLinks);
    } catch (e) {
      _handleError(e, "Path.typeOfAsync");
      return FileSystemEntityType.notFound;
    }
  }

  /// Generates a unique name appending `-(idx)` until a unique name is found asynchronously.
  ///
  /// This does not create the entity, it only generates a name.
  Future<String?> getUniqueNameAsync(String path) async {
    try {
      final typeOfPath = await typeOfAsync(path, followLinks: false);

      if (typeOfPath == FileSystemEntityType.notFound) {
        return path;
      }

      final dir = pth.dirname(path);
      String base;
      String ext = "";

      if (typeOfPath == FileSystemEntityType.directory) {
        base = pth.basename(path);
      } else {
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
      } while (await typeOfAsync(newPath, followLinks: false) !=
          FileSystemEntityType.notFound);

      return newPath;
    } catch (e) {
      _handleError(e, "Path.getUniqueNameAsync");
      return null;
    }
  }

  /// Copies a directory from [source] to [destination] asynchronously.
  ///
  /// If [forceReplace] is `true`, it will overwrite the destination if it exists.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> copyDirAsync(
    String source,
    String destination, {
    bool forceReplace = false,
  }) async {
    try {
      final dir = Directory(source);
      if (!await dir.exists()) {
        return false;
      }

      if (pth.isWithin(source, destination)) {
        throw ArgumentError("Destination cannot be a subdirectory of source");
      }

      final destDir = Directory(destination);
      if (await destDir.exists()) {
        if (forceReplace) {
          await destDir.delete(recursive: true);
        } else {
          return false;
        }
      }

      await destDir.create(recursive: true);

      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        final relativePath = pth.relative(entity.path, from: source);
        final newPath = pth.join(destination, relativePath);

        if (entity is File) {
          final destFile = File(newPath);
          if (await destFile.exists()) await destFile.delete();
          await entity.copy(newPath);
        } else if (entity is Directory) {
          await Directory(newPath).create(recursive: true);
        } else if (entity is Link) {
          await Link(newPath).create(await entity.target());
        }
      }

      return true;
    } catch (e) {
      _handleError(e, "Path.copyDirAsync");
      return false;
    }
  }

  /// Fallback to copy and then delete a file asynchronously for cross-device moves.
  Future<bool> _copyAndDeleteFileAsync(
    String source,
    String destination, {
    bool forceReplace = false,
  }) async {
    try {
      if (await copyFileAsync(source, destination, forceReplace: forceReplace)) {
        await File(source).delete();
        return true;
      }
      return false;
    } catch (e) {
      _handleError(e, "Path._copyAndDeleteFileAsync");
      return false;
    }
  }

  /// Fallback to copy and then delete a directory asynchronously for cross-device moves.
  Future<bool> _copyAndDeleteDirAsync(
    String source,
    String destination, {
    bool forceReplace = false,
  }) async {
    try {
      if (await copyDirAsync(source, destination, forceReplace: forceReplace)) {
        await Directory(source).delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      _handleError(e, "Path._copyAndDeleteDirAsync");
      return false;
    }
  }

  // --- Link Helpers ---

  /// Creates a symbolic link at [path] pointing to [target] asynchronously.
  Future<bool> makeLinkAsync(String path, String target) async {
    try {
      await Link(path).create(target, recursive: true);
      return true;
    } catch (e) {
      _handleError(e, "Path.makeLinkAsync");
      return false;
    }
  }

  /// Resolves the target of a symbolic link asynchronously.
  Future<String?> resolveLinkAsync(String path) async {
    try {
      if (await isSymbolicLinkAsync(path)) {
        return await Link(path).target();
      }
      return null;
    } catch (e) {
      _handleError(e, "Path.resolveLinkAsync");
      return null;
    }
  }

  // --- Metadata & Info Helpers ---

  /// Returns the stats for the given path asynchronously.
  Future<FileStat> getStatAsync(String path) => FileStat.stat(path);

  /// Returns the size of the file or directory in bytes asynchronously.
  Future<int> getSizeAsync(String path) async {
    try {
      final entity = await FileSystemEntity.type(path);
      if (entity == FileSystemEntityType.file) {
        return await File(path).length();
      } else if (entity == FileSystemEntityType.directory) {
        int totalSize = 0;
        await for (final file in Directory(path).list(recursive: true)) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
        return totalSize;
      }
      return 0;
    } catch (e) {
      _handleError(e, "Path.getSizeAsync");
      return 0;
    }
  }

  /// Checks if a directory is empty asynchronously.
  Future<bool> isEmptyAsync(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return true;
      return await dir.list().isEmpty;
    } catch (e) {
      _handleError(e, "Path.isEmptyAsync");
      return true;
    }
  }

  /// Clears all contents of a directory without deleting the directory itself asynchronously.
  Future<bool> clearDirAsync(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return true;
      await for (final entity in dir.list()) {
        await entity.delete(recursive: true);
      }
      return true;
    } catch (e) {
      _handleError(e, "Path.clearDirAsync");
      return false;
    }
  }

  // --- Content Helpers ---

  /// Reads the entire file as bytes asynchronously.
  Future<Uint8List?> readAsBytesAsync(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      _handleError(e, "Path.readAsBytesAsync");
      return null;
    }
  }

  /// Writes bytes to a file asynchronously.
  Future<bool> writeAsBytesAsync(
    String path,
    Uint8List bytes, {
    bool append = false,
  }) async {
    try {
      final file = File(path);
      if (!await file.exists()) await file.create(recursive: true);
      await file.writeAsBytes(bytes, mode: append ? FileMode.append : FileMode.write);
      return true;
    } catch (e) {
      _handleError(e, "Path.writeAsBytesAsync");
      return false;
    }
  }

  // --- Temp Helpers ---

  /// Creates a temporary directory asynchronously.
  Future<Directory> createTempDirAsync([String prefix = 'temp_']) async {
    return await Directory.systemTemp.createTemp(prefix);
  }

  /// Creates a temporary file asynchronously.
  Future<File> createTempFileAsync([String prefix = 'temp_']) async {
    final tempDir = await Directory.systemTemp.createTemp(prefix);
    return await File(pth.join(tempDir.path, 'file.tmp')).create();
  }

  /// Returns a stream of entities in the directory at the given [path] asynchronously.
  Stream<FileSystemEntity> listAsync(
    String path, {
    bool recursive = false,
    bool followLinks = false,
  }) {
    try {
      return Directory(path).list(recursive: recursive, followLinks: followLinks);
    } catch (e) {
      _handleError(e, "Path.listAsync");
      return const Stream.empty();
    }
  }

  /// Sets the last modified time of the file asynchronously.
  Future<bool> setLastModifiedAsync(String path, DateTime time) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.setLastModified(time);
        return true;
      }
      return false;
    } catch (e) {
      _handleError(e, "Path.setLastModifiedAsync");
      return false;
    }
  }

  /// Reads the entire file as a list of lines asynchronously.
  Future<List<String>?> readLinesAsync(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsLines();
      }
      return null;
    } catch (e) {
      _handleError(e, "Path.readLinesAsync");
      return null;
    }
  }
}
