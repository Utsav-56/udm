// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Configuration and strategy definitions for the UDM downloader.
///
/// This library contains the [DownloaderConfig] class and the [DownloadType]
/// enum, which together define how a file should be downloaded, where it
/// should be saved, and how progress should be reported.
library;

import 'dart:convert';
import 'dart:io';
import 'package:udm/helpers/path_helpers/path_helpers.dart';

/// Specifies the strategy the downloader should employ to fetch the remote file.
enum DownloadType {
  /// Forces the downloader to use a single persistent HTTP stream.
  ///
  /// This is recommended for servers that do not support Range requests or
  /// have strict limits on concurrent connections.
  single,

  /// Automatically selects the most efficient download strategy.
  ///
  /// The system will attempt a multi-threaded download if the server supports
  /// Range requests and the file size justifies the overhead. Otherwise, it
  /// falls back to a single stream.
  smart,
}

/// A comprehensive configuration container for the [Downloader].
///
/// [DownloaderConfig] centralizes all settings related to a download operation,
/// including filesystem paths, network headers, concurrency levels, and UI
/// preferences. It supports hierarchical configuration: explicit user input
/// overrides saved preferences, which in turn override system defaults.
class DownloaderConfig {
  /// The directory where the downloaded file will be saved.
  ///
  /// **Note**: If null, the system's default download directory is used.
  /// **Caution**: Ensure the process has write permissions for this directory.
  /// Explicitly set output directory provided during instantiation.
  String? _explicitOutputDir;

  /// Explicitly set filename provided during instantiation.
  String? _explicitFilename;



  /// The strategy used for fetching the file (e.g., [DownloadType.smart]).
  final DownloadType downloadType;

  /// The interval (in milliseconds) for synchronizing progress between worker
  /// isolates and the main thread.
  ///
  /// This interval also dictates the frequency of [Downloader.timerFunction]
  /// execution. Defaults to 500ms.
  final int progressSyncInterval;



  /// The number of concurrent connections (threads/isolates) to use for
  /// multi-threaded downloads.
  ///
  /// Higher values can increase throughput but also increase CPU and memory
  /// overhead. Values between 8 and 12 are typically optimal.
  final int threadCount;

  /// Optional HTTP headers to include in every request (e.g., User-Agent, Authorization).
  final Map<String, String>? headers;

  /// Optional cookie string to be sent with the request headers.
  final String cookie;

  /// If `true`, the system prefers the file extension resolved from server
  /// headers over any extension provided in the user's preferred filename.
  final bool preferResolvedExtension;

  /// Internal map of settings loaded from a persistent configuration file.
  Map<String, dynamic> _userPreference = {};

  /// Resolves the current filename based on hierarchy (Explicit > Preferred > Default).
  String? get _filename {
    return _explicitFilename ?? _userPreference['preferredFilename'];
  }

  /// Returns `true` if a non-empty filename has been explicitly set.
  bool get isFilenameSet => _filename != null && _filename!.isNotEmpty;

  /// The resolved filename, defaulting to "UDM-Downloaded-File" if none is set.
  String get filename => _filename ?? "UDM-Downloaded-File";

  /// Sets or clears the explicit filename preference.
  set filename(String? name) {
    _explicitFilename = (name == null || name.isEmpty) ? null : name;
  }

  /// Sets the output directory and ensures all parent directories are created.
  set outputDir(String? dir) {
    if (dir != null && dir.isNotEmpty) {
      p.mkDirAll(dir);
      _explicitOutputDir = dir;
    }
  }

  /// Calculates the absolute file path, ensuring uniqueness to avoid overwriting.
  String get absoluteFilename {
    final baseDir = outputDir;
    final name = filename;
    // We calculate uniqueness at the moment the path is requested
    return p.getUniqueName(p.join(baseDir, name));
  }

  /// Resolves the current output directory based on hierarchy (Explicit > Preferred > System Default).
  String get outputDir {
    return _explicitOutputDir ??
        _userPreference['outputDir'] ??
        p.getDownloadDir(); // Layer 3: Hard-coded Default
  }

  /// Creates a new [DownloaderConfig] with customizable settings.
  ///
  /// - [saveDir]: Directory where the file will be saved.
  /// - [filename]: Preferred name for the file.
  /// - [verbose]: Enable low-level HTTP debugging logs.
  /// - [downloadType]: Strategy for downloading (defaults to [DownloadType.smart]).
  /// - [progressSyncInterval]: Milliseconds between progress updates (defaults to 500).
  /// - [showProgressInTerminal]: Render UI in terminal (defaults to true if terminal detected).
  /// - [headers]: Custom HTTP headers.
  /// - [cookie]: Custom HTTP cookie.
  /// - [threadCount]: Number of isolates for multi-threading (defaults to 10).
  /// - [isVerboseMode]: Enable detailed step logging.
  /// - [preferResolvedExtension]: Append extensions from headers (defaults to true).
  DownloaderConfig({
    String? saveDir,
    String? filename,
    this.downloadType = DownloadType.smart,
    this.progressSyncInterval = 500,
    this.headers,
    this.cookie = "",
    this.threadCount = 10,
    this.preferResolvedExtension = true,
  }) {
    populateConfigs();

    //Assign "User" Layer (this overrides the saved layer in getters)
    outputDir = saveDir;
    this.filename = filename;
  }

  /// Resolves the absolute path to the global UDM configuration file.
  ///
  /// Respects the `UDM_CONFIG_PATH` environment variable if present; otherwise,
  /// defaults to `~/.udm/config.json`.
  static String get configPath {
    String path;
    String fallbackPath = p.join(p.getHomeDir(), ".udm", "config.json");
    path = Platform.environment['UDM_CONFIG_PATH'] ?? fallbackPath;
    return path;
  }

  /// Reads and parses the persistent configuration file into [_userPreference].
  void populateConfigs() {
    try {
      // TODO: need to implemnet it properly
      _userPreference = {};
    } catch (e) {
      print("Error while reading config file: $e");
      _userPreference = {};
    }
  }

  /// Updates the persistent configuration file with the provided [configs].
  ///
  /// Merges [configs] with the existing file content. Creates the file if it
  /// does not exist.
  static void updateConfig(Map<String, dynamic> configs) {
    final file = File(configPath);
    Map<String, dynamic> json = {};

    if (file.existsSync()) {
      json = jsonDecode(file.readAsStringSync());
    }

    json.addAll(configs);
    file.writeAsStringSync(jsonEncode(json));
  }

  /// Creates a copy of the current [DownloaderConfig] with updated properties.
  DownloaderConfig copyWith({
    String? saveDir,
    String? filename,
    DownloadType? downloadType,
    int? progressSyncInterval,
    Map<String, String>? headers,
    String? cookie,
    int? threadCount,
    bool? preferResolvedExtension,
  }) {
    return DownloaderConfig(
      saveDir: saveDir ?? outputDir,
      filename: filename ?? this.filename,
      downloadType: downloadType ?? this.downloadType,
      progressSyncInterval: progressSyncInterval ?? this.progressSyncInterval,
      headers: headers ?? this.headers,
      cookie: cookie ?? this.cookie,
      threadCount: threadCount ?? this.threadCount,
      preferResolvedExtension: preferResolvedExtension ?? this.preferResolvedExtension,
    );
  }

  /// A default configuration instance used when no specific settings are provided.
  static final DownloaderConfig defaultInstance = DownloaderConfig(
    saveDir: p.getDownloadDir(),
    filename: "UDM-Downloaded-File",
    downloadType: DownloadType.smart,
    progressSyncInterval: 500,
    headers: null,
    cookie: "",
    threadCount: 10,
    preferResolvedExtension: true,
  );

  DownloaderConfig get defaultValue => defaultInstance;

  String get configFilePath => p.join(p.getHomeDir(), ".udm", "downloader_config.json");

  DownloaderConfig fromJson(Map<String, dynamic> json) {
    return DownloaderConfig(
      saveDir: json['saveDir'],
      filename: json['filename'],
      downloadType: DownloadType.values[json['downloadType']],
      progressSyncInterval: json['progressSyncInterval'],
      headers: json['headers'],
      cookie: json['cookie'],
      threadCount: json['threadCount'],
      preferResolvedExtension: json['preferResolvedExtension'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saveDir': outputDir,
      'filename': filename,
      'downloadType': downloadType.index,
      'progressSyncInterval': progressSyncInterval,
      'headers': headers,
      'cookie': cookie,
      'threadCount': threadCount,
      'preferResolvedExtension': preferResolvedExtension,
    };
  }

  String tojsonString() {
    return const JsonEncoder.withIndent("    ").convert(toJson());
  }
}
