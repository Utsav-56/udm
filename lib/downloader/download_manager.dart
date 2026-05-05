// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Central management system for handling concurrent downloads.
///
/// This library provides the [DownloadManager] class which implements a queued
/// execution model. It manages concurrent active downloads, fetches metadata,
/// and routes to the appropriate download strategy (multi-stream or single-stream).
library;

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io';
import 'package:udm/downloader/downloader.dart';
import 'package:udm/downloader/head_parser.dart';
import 'package:udm/downloader/models/downloader_config.dart';
import 'package:udm/helpers/path_helpers/path_helpers.dart';

/// Represents a queued download operation awaiting execution.
///
/// Holds the target [url] and [config] while exposing a [completer] that
/// will resolve with the spawned [Downloader] instance once processing begins.
class DownloadTask {
  /// The remote URL of the file to be downloaded.
  final String url;

  /// Configuration settings for this specific download.
  final DownloaderConfig config;

  /// Resolves with the created [Downloader] instance when the task is spawned.
  final Completer<Downloader> completer = Completer<Downloader>();

  /// Creates a new [DownloadTask].
  DownloadTask({required this.url, required this.config});
}

/// The central controller for all download operations within UDM.
///
/// [DownloadManager] implements a queue system to restrict the maximum number
/// of concurrent downloads (up to [maxConcurrentDownloads]). It automatically
/// fetches file metadata via [sendHeadRequest] and spawns either a
/// [MultiStreamDownload] or [SingleStreamDownloader] based on server support.
class DownloadManager {
  /// Internal singleton instance of the [DownloadManager].
  static final DownloadManager _instance = DownloadManager._internal();

  /// Factory constructor to retrieve the singleton [DownloadManager] instance.
  factory DownloadManager() => _instance;

  /// Internal constructor for singleton initialization.
  DownloadManager._internal();

  /// A registry of all instantiated downloaders, keyed by their unique timestamped ID.
  ///
  /// This map allows external components to signal specific downloaders (e.g., pause, resume, cancel).
  final Map<String, Downloader> spawnedDownloaders = {};

  /// The internal queue of pending [DownloadTask] instances.
  final List<DownloadTask> _queue = [];

  /// The current number of active downloads being processed.
  int _activeDownloads = 0;

  /// The maximum number of downloads allowed to run concurrently.
  static const int maxConcurrentDownloads = 4;

  /// Adds a new download operation to the queue.
  ///
  /// If the number of active downloads is less than [maxConcurrentDownloads],
  /// the download starts immediately. Otherwise, it waits in the queue.
  ///
  /// Returns a [Future] that completes with the instantiated [Downloader]
  /// once the task starts executing.
  Future<Downloader> enqueue(String url, DownloaderConfig config) {
    final task = DownloadTask(url: url, config: config);
    _queue.add(task);
    _processQueue();
    return task.completer.future;
  }

  /// Processes the next available task in the queue if concurrency limits allow.
  ///
  /// Recursively triggers itself upon completion of a task to ensure continuous
  /// queue processing.
  Future<void> _processQueue() async {
    if (_activeDownloads >= maxConcurrentDownloads || _queue.isEmpty) {
      return;
    }

    _activeDownloads++;
    final task = _queue.removeAt(0);

    try {
      final downloader = await _spawnDownloader(task.url, task.config);
      spawnedDownloaders[downloader.id] = downloader;
      task.completer.complete(downloader);

      // We start the download and wait for it to finish before freeing the slot
      await downloader.start();
    } catch (e, st) {
      if (!task.completer.isCompleted) {
        task.completer.completeError(e, st);
      }
    } finally {
      _activeDownloads--;
      // Process next item in queue when current task finishes
      _processQueue();
    }
  }

  /// Determines the optimal download strategy and instantiates the appropriate [Downloader].
  ///
  /// This method performs an initial HEAD request to gather file metadata. It
  /// then spawns a [MultiStreamDownload] if supported by the server, otherwise
  /// defaulting to a [SingleStreamDownloader].
  Future<Downloader> _spawnDownloader(String url, DownloaderConfig config) async {
    final client = HttpClient()
      ..maxConnectionsPerHost = 3
      ..connectionTimeout = const Duration(seconds: 10)
      ..idleTimeout = const Duration(seconds: 5);

    final headerInfo = await sendHeadRequest(Uri.parse(url), client);

    Downloader downloader;

    if (headerInfo.supportsMultiStream && config.downloadType != DownloadType.single) {
      // Close the client since multi-stream isolate manages its own network connections
      client.close();
      downloader = MultiStreamDownload(url: url, headerInfo: headerInfo, config: config);
    } else {
      // Reuse the existing client for the single stream download
      downloader = SingleStreamDownloader(
        url: url,
        headerInfo: headerInfo,
        config: config,
        client: client,
      );
    }

    return downloader;
  }
}

/// the file types in udm downloader manager
/// the download dir will be like preferredDir/filetype/
class FileTypeEntry {
  final String name;

  // set to ensure no duplicate file type
  final Set<String> extensions;

  /// the preferred save dir for this especific file type
  final String preferredSaveDir;

  const FileTypeEntry({
    required this.name,
    required this.extensions,
    required this.preferredSaveDir,
  });

  factory FileTypeEntry.fromJson(Map<String, dynamic> jsonMap) {
    return FileTypeEntry(
      name: jsonMap['name'],
      extensions: json.decode(jsonMap['extensions']),
      preferredSaveDir: jsonMap['preferredSaveDir'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,

      /// we encode the set to a string using json.encode to make it serializable.
      'extensions': json.encode(extensions),
      'preferredSaveDir': preferredSaveDir,
    };
  }
}

/// the default file types and their preferred save dirs
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
    preferredSaveDir: "",
  ),
  const FileTypeEntry(
    name: "Images",
    extensions: {".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".tiff", ".svg"},
    preferredSaveDir: "",
  ),
  const FileTypeEntry(
    name: "Videos",
    extensions: {".mp4", ".avi", ".mov", ".wmv", ".flv", ".mkv"},
    preferredSaveDir: "",
  ),
  const FileTypeEntry(
    name: "Audio",
    extensions: {".mp3", ".wav", ".aac", ".flac", ".ogg", ".m4a"},
    preferredSaveDir: "",
  ),
  const FileTypeEntry(
    name: "Archives",
    extensions: {".zip", ".rar", ".7z", ".tar", ".gz"},
    preferredSaveDir: "",
  ),
];

class FileTypePreference {
  late final List<FileTypeEntry> types;

  FileTypePreference({List<FileTypeEntry>? types}) : types = types ?? defaultFileTypes;
}

/// the preferences for the manager settings
class ManagerPreferences {
  // main worker configs
  late final int maxConcurrentDownloads;
  late final int threadCount;
  late final String userAgent;
  late final Map<String, String> customHeaders;

  // error handling configs
  late final bool retryOnFailure;
  late final int maxRetries;

  // http client configs
  late final int timeout;
  late final int maxConnectionsPerHost;
  late final int idleTimeout;
  late final bool followRedirects;
  late final bool ignoreBadCertificate;

  // save path prefs
  late final String savePath;
  late final String tempPath;

  // file naming prefs
  late final bool deleteFileOnCancel;

  // if true then it will append the resolved server file extension or else it does nothing.
  late final bool preferServerFileExtension;

  // speed limit prefs
  late final int maxSpeed;
  late final int minSpeed;

  ManagerPreferences({
    int? maxConcurrentDownloads,
    int? threadCount,
    String? userAgent,
    Map<String, String>? customHeaders,

    // error handling configs
    bool? retryOnFailure,
    int? maxRetries,

    // http client configs
    int? timeout,
    int? maxConnectionsPerHost,
    int? idleTimeout,
    bool? followRedirects,
    bool? ignoreBadCertificate,

    // save path prefs
    String? savePath,
    String? tempPath,

    // file naming prefs
    bool? deleteFileOnCancel,

    // if true then it will append the resolved server file extension or else it does nothing.
    bool? preferServerFileExtension,

    // speed limit prefs
    int? maxSpeed,
    int? minSpeed,
  });

  factory ManagerPreferences.defaultValue() => ManagerPreferences(
    maxConcurrentDownloads: 4,
    threadCount: 4,
    userAgent: '',
    customHeaders: {},
    retryOnFailure: true,
    maxRetries: 3,
    timeout: 10,
    maxConnectionsPerHost: 3,
    idleTimeout: 5,
    followRedirects: true,
    ignoreBadCertificate: false,
    savePath: Directory.current.path,
    tempPath: Directory.current.path,
    deleteFileOnCancel: true,
    preferServerFileExtension: true,
    maxSpeed: 0,
    minSpeed: 0,
  );

  static String get prefFilePath =>
      p.join(p.getHomeDir(), '.udm', 'config', 'prefs.json');

  static void _ensurePrefsFile() {
    final file = File(prefFilePath);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
      file.writeAsStringSync(json.encode(ManagerPreferences.defaultValue().toMap()));
    }
  }

  /// this will load the preference from json config
  factory ManagerPreferences.fromFile() {
    final file = File(prefFilePath);
    final defaultValue = ManagerPreferences.defaultValue();

    if (!file.existsSync()) {
      return defaultValue;
    }

    final jsonString = file.readAsStringSync();
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

    return ManagerPreferences(
      maxConcurrentDownloads:
          jsonMap["maxConcurrentDownloads"] ?? defaultValue.maxConcurrentDownloads,
      threadCount: jsonMap["threadCount"] ?? defaultValue.threadCount,
      userAgent: jsonMap["userAgent"] ?? defaultValue.userAgent,
      customHeaders: jsonMap["customHeaders"] ?? defaultValue.customHeaders,
      retryOnFailure: jsonMap["retryOnFailure"] ?? defaultValue.retryOnFailure,
      maxRetries: jsonMap["maxRetries"] ?? defaultValue.maxRetries,
      timeout: jsonMap["timeout"] ?? defaultValue.timeout,
      maxConnectionsPerHost:
          jsonMap["maxConnectionsPerHost"] ?? defaultValue.maxConnectionsPerHost,
      idleTimeout: jsonMap["idleTimeout"] ?? defaultValue.idleTimeout,
      followRedirects: jsonMap["followRedirects"] ?? defaultValue.followRedirects,
      ignoreBadCertificate:
          jsonMap["ignoreBadCertificate"] ?? defaultValue.ignoreBadCertificate,
      savePath: jsonMap["savePath"] ?? defaultValue.savePath,
      tempPath: jsonMap["tempPath"] ?? defaultValue.tempPath,
      deleteFileOnCancel:
          jsonMap["deleteFileOnCancel"] ?? defaultValue.deleteFileOnCancel,
      preferServerFileExtension:
          jsonMap["preferServerFileExtension"] ?? defaultValue.preferServerFileExtension,
      maxSpeed: jsonMap["maxSpeed"] ?? defaultValue.maxSpeed,
      minSpeed: jsonMap["minSpeed"] ?? defaultValue.minSpeed,
    );
  }

  /// this will save the preference to json config
  void saveToFile() {
    _ensurePrefsFile();
    final file = File(prefFilePath);

    final jsonMap = toMap();
    file.writeAsStringSync(json.encode(jsonMap));
  }

  /// this will convert the preference to json map
  Map<String, dynamic> toMap() => {
    "maxConcurrentDownloads": maxConcurrentDownloads,
    "threadCount": threadCount,
    "userAgent": userAgent,
    "customHeaders": customHeaders,
    "retryOnFailure": retryOnFailure,
    "maxRetries": maxRetries,
    "timeout": timeout,
    "maxConnectionsPerHost": maxConnectionsPerHost,
    "idleTimeout": idleTimeout,
    "followRedirects": followRedirects,
    "ignoreBadCertificate": ignoreBadCertificate,
    "savePath": savePath,
    "tempPath": tempPath,
    "deleteFileOnCancel": deleteFileOnCancel,
    "preferServerFileExtension": preferServerFileExtension,
    "maxSpeed": maxSpeed,
    "minSpeed": minSpeed,
  };
}
