import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:udm/helpers/path_helpers/path_helpers.dart';
import 'package:udm/models/saveable_config.dart';

/// Specifies the strategy the downloader should employ to fetch the file.
///
/// **Why**: Servers vary in their support for concurrent range requests. This enum
/// allows users to force a safe path or let the system optimize.
enum DownloadType {
  /// Forces the downloader to use a single persistent stream.
  ///
  /// **Why**: Useful for testing or for servers that explicitly ban multi-connections.
  /// **How**: Set this in [DownloaderConfig] to bypass multi-thread logic.
  single,

  /// Automatically chooses the best method (Multi-stream if supported, fallback to Single).
  ///
  /// **Why**: Provides the best performance balance without risking failure on non-resumable servers.
  /// **Note**: This is the default and recommended type.
  smart,
}

/// Configuration container for all parameters required by the [Downloader].
///
/// **Why**: Centralizes settings like output paths, thread counts, and headers to
/// ensure consistent behavior across different download instances.
/// **How**: Can be instantiated manually or loaded from a saved JSON configuration.
class DownloaderConfig extends SaveableConfig<DownloaderConfig>
    implements Savable<DownloaderConfig> {
  /// The directory where the downloaded file will be saved.
  ///
  /// **Note**: If null, the system's default download directory is used.
  /// **Caution**: Ensure the process has write permissions for this directory.
  // Layer 1: Explicit User Input (Keep null if not provided)
  String? _explicitOutputDir;

  /// The preferred filename for the saved file.
  ///
  /// **Why**: Allows users to override the default filename resolved from headers or URL.
  /// **Note**: If a file with the same name exists, a unique suffix will be appended.
  String? _explicitFilename;

  /// Whether to print detailed internal logs to the terminal.
  ///
  /// **Why**: Essential for debugging communication between isolates and servers.
  final bool verbose;

  /// the [DownloadType] that the downloader will use to download the file, it is optional and defaults to [DownloadType.smart]
  final DownloadType downloadType;

  /// the time duration of progress syncing in milliseconds
  /// to prevent the cpu wastage we wont be polling the status too frequently
  /// set this to a suitable [Duration] value in milliseconds
  ///
  /// Note:: this is the same duration that will be used in the [Downloader.timerFunction] to send the timer tick to status and show progress
  /// defaults to 500 milliseconds
  final int progressSyncInterval;

  /// either to show the progress in the terminal or not
  /// if this is [false] then we will not be showing the progress in the terminal
  ///
  /// This is different from [verbose] in that this only controls the progress display
  /// while [verbose] controls all logs
  ///
  /// defaults to true
  late final bool showProgressInTerminal;

  /// if this is true then we will log every steps into the terminal
  ///
  /// this depends upoon the [showProgressInTerminal] value
  ///
  /// if [showProgressInTerminal] is false then we will not be logging any steps even if this is true
  ///
  /// defaults to false
  final bool isVerboseMode;

  /// the no of threads to be used if in case the multi stream download is supported
  ///
  /// this value will have no effect if the server does not support multi stream download
  ///
  /// Choose a appropriate value as this is repsonsible to spawn isolate(threads) which consumes CPU power
  /// this is optional and defaults to 10
  ///
  /// Note:: that setting this value to a huge doesnot boost the speed, if your wifi is 20mbps download will never ever be more then 20mbps remember that
  /// in some case the download will be slowed if too many spawned as each has own overhead, latency, and CPU usage
  /// the 8-12 is a ideal value for most cases
  ///
  final int threadCount;

  /// the headers to be sent with the request, optional
  ///
  /// This will be attached to every request the downloader will make
  ///
  /// If making request to a protected site then setting this is ideal or else download may fail
  ///
  final Map<String, String>? headers;

  /// the cookie string to be sent with the request, optional
  ///
  /// This will be attached to every request the downloader will make
  ///
  /// If making request to a protected site then setting this is ideal or else download may fail
  ///
  final String cookie;

  /// if this is true then we will append the extension from the header info to the filename
  /// even if the filename already has an extension
  ///
  /// defaults to true
  final bool preferResolvedExtension;

  /// in each instance creation this will be initialized with the saved config or user preference
  ///
  /// any changes made to the config file afterwards is not reflected in the existing instances.
  Map<String, dynamic> _userPreference = {};

  /// the getter for the filename
  ///
  /// it will return the resolved filename which is either from the user preference or from the header info or from the url
  /// it can stay null in that  case the downloader determines either by the header or use default name
  String? get _filename {
    return _explicitFilename ?? _userPreference['preferredFilename'];
  }

  /// returns true if the filename is set by the user
  bool get isFilenameSet => _filename != null && _filename!.isNotEmpty;

  /// the final filename to be used
  String get filename => _filename ?? "UDM-Downloaded-File";

  /// the setter for the filename
  ///
  /// it will update the filename in the user preference
  set filename(String? name) {
    _explicitFilename = (name == null || name.isEmpty) ? null : name;
  }

  /// setter for output dir
  set outputDir(String? dir) {
    if (dir != null && dir.isNotEmpty) {
      p.mkDirAll(dir);
      _explicitOutputDir = dir;
    }
  }

  /// Resolves the full path and ensures a unique name to avoid overwriting
  String get absoluteFilename {
    final baseDir = outputDir;
    final name = filename;
    // We calculate uniqueness at the moment the path is requested
    return p.getUniqueName(p.join(baseDir, name));
  }

  String get outputDir {
    return _explicitOutputDir ??
        _userPreference['outputDir'] ??
        p.getDownloadDir(); // Layer 3: Hard-coded Default
  }

  DownloaderConfig({
    /// the path where the file will be saved, if not given then we will try to get from preference or default dir
    String? saveDir,

    /// if not given then we will try to get from header info
    String? filename,
    this.verbose = false,
    this.downloadType = DownloadType.smart,
    this.progressSyncInterval = 500,
    bool? showProgressInTerminal,
    this.headers,
    this.cookie = "",
    this.threadCount = 10,
    this.isVerboseMode = false,
    this.preferResolvedExtension = true,
  }) {
    populateConfigs();

    //Assign "User" Layer (this overrides the saved layer in getters)
    this.outputDir = saveDir;
    this.filename = filename;

    /// if the stdout has no terminal connected then we will not be showing the progress
    if (stdout.hasTerminal) {
      this.showProgressInTerminal = showProgressInTerminal ?? true;
    } else {
      this.showProgressInTerminal = false;
    }
  }

  /// finds the path to the config file
  /// it depends upoon the platform dir and if not found then it will make a new one defaulting to the home dir
  static String get configPath {
    String path;
    String fallbackPath = p.join(p.getHomeDir(), ".udm", "config.json");
    path = Platform.environment['UDM_CONFIG_PATH'] ?? fallbackPath;
    return path;
  }

  /// reads the config file and populates the _userPreference
  ///
  void populateConfigs() {
    try {
      _userPreference = readSavedConfig();
    } catch (e) {
      print("Error while reading config file: $e");
      _userPreference = {};
    }
  }

  /// updates the config file with the new configs
  ///
  /// it will overwrite the file if it exists
  /// if the path does not exist then it will create it
  ///
  /// the config file is a json file that contains the following fields:
  /// - "outputDir": the directory where the downloaded file will be saved
  /// - "preferredFilename": the preferred filename that you want to use for the saved file
  /// - "verbose": the [DownloadType] that the downloader will use to download the file
  /// - "downloadType": the [DownloadType] that the downloader will use to download the file
  static void updateConfig(Map<String, dynamic> configs) {
    final file = File(configPath);
    Map<String, dynamic> json = {};

    if (file.existsSync()) {
      json = jsonDecode(file.readAsStringSync());
    }

    json.addAll(configs);
    file.writeAsStringSync(jsonEncode(json));
  }

  /// copies the current [DownloaderConfig] with the new states
  /// if any of the parameters is not provided then it will use the current value
  DownloaderConfig copyWith({
    String? fileUrl,
    String? saveDir,
    String? filename,
    DownloadType? downloadType,
    int? progressSyncInterval,
    bool? isVerboseMode,
    bool? showProgressInTerminal,
    Map<String, String>? headers,
    String? cookie,
    int? threadCount,
    bool? preferResolvedExtension,
  }) {
    return DownloaderConfig(
      saveDir: saveDir ?? this.outputDir,
      filename: filename ?? this.filename,
      downloadType: downloadType ?? this.downloadType,
      progressSyncInterval: progressSyncInterval ?? this.progressSyncInterval,
      isVerboseMode: isVerboseMode ?? this.isVerboseMode,
      showProgressInTerminal: showProgressInTerminal ?? this.showProgressInTerminal,
      headers: headers ?? this.headers,
      cookie: cookie ?? this.cookie,
      threadCount: threadCount ?? this.threadCount,
      preferResolvedExtension: preferResolvedExtension ?? this.preferResolvedExtension,
    );
  }

  /// this instance is used in case there is no other config available or user has not set any config
  /// [Downloader] class uses this instance if there is no config provided for it
  static final DownloaderConfig defaultInstance = DownloaderConfig(
    saveDir: p.getDownloadDir(),
    filename: "UDM-Downloaded-File",
    downloadType: DownloadType.smart,
    progressSyncInterval: 500,
    isVerboseMode: false,
    showProgressInTerminal: true,
    headers: null,
    cookie: "",
    threadCount: 10,
    preferResolvedExtension: true,
  );

  @override
  DownloaderConfig get defaultValue => defaultInstance;

  @override
  String get configFilePath => p.join(p.getHomeDir(), ".udm", "downloader_config.json");

  @override
  DownloaderConfig fromJson(Map<String, dynamic> json) {
    return DownloaderConfig(
      saveDir: json['saveDir'],
      filename: json['filename'],
      downloadType: DownloadType.values[json['downloadType']],
      progressSyncInterval: json['progressSyncInterval'],
      isVerboseMode: json['isVerboseMode'],
      showProgressInTerminal: json['showProgressInTerminal'],
      headers: json['headers'],
      cookie: json['cookie'],
      threadCount: json['threadCount'],
      preferResolvedExtension: json['preferResolvedExtension'] ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'saveDir': outputDir,
      'filename': filename,
      'downloadType': downloadType.index,
      'progressSyncInterval': progressSyncInterval,
      'isVerboseMode': isVerboseMode,
      'showProgressInTerminal': showProgressInTerminal,
      'headers': headers,
      'cookie': cookie,
      'threadCount': threadCount,
      'preferResolvedExtension': preferResolvedExtension,
    };
  }

  @override
  String tojsonString() {
    return const JsonEncoder.withIndent("    ").convert(toJson());
  }
}
