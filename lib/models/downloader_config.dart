import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:udm/helpers/path_helpers/path_helpers.dart';

/// Download type specifies what method of download the downloader should use
///
/// It can either be single or smart download.
///
/// We cannot always ensure that multi stream is possible so, there is no multi stream only type
enum DownloadType {
  /// forces the downloader to use single stream download
  /// even if the server supports range requests. This is useful for testing and for servers that have issues with range requests.
  single,

  /// allows the downloader to choose the best download method based on the server's capabilities.
  /// if server supports then we will use multi stream download, otherwise we will fall back to single stream download.
  /// it is the default download type and is recommended for most use cases
  smart,
}

/// The config needed for downloader to download the file.
/// It includes all the configs or that the downloader needs to set before starting the download
class DownloaderConfig {
  /// the url of the file to be downloaded
  ///
  /// it is required and cannot be empty
  late final Uri url;

  /// the directory where the downloaded file will be saved
  /// If not provided then it will use the default download directory of the system or the current directory as fallback
  ///
  /// it is optional but if provided then, ensure that the path is valid and you actually have write prrmisisons in that directory,
  /// otherwise it will throw an error when the downloader tries to save the file
  late final String? _outputDir;

  /// the preferred filename that you want to use for the saved file,
  /// it is purely optional
  /// if not provided then we will try to get the filename from header info, url respectively, or else we will default to "Udm-downloaded-file"
  ///
  /// If provided and the filename already exists then a unique suffix will automatically be added to the filename to avoid the overwritting issue of existing file
  ///
  String? _preferredFilename;

  /// This is for debugging purpose,
  /// if it is verbose then it will print the logs of the download process in the terminals std io, otherwise it will not print any logs
  /// it is purely optional and  defaults to false
  ///
  /// this will just print the logs in terminal,
  /// but if the process is not attached to a terminal then no matter if user gives verbose or not it will be false in that case.
  final bool verbose;

  /// the [DownloadType] that the downloader will use to download the file, it is optional and defaults to [DownloadType.smart]
  final DownloadType downloadType;

  /// in each instance creation this will be initialized with the saved config or user preference
  ///
  /// any changes made to the config file afterwards is not reflected in the existing instances.
  Map<String, dynamic> _userPreference = {};

  /// the getter for the filename
  ///
  /// it will return the resolved filename which is either from the user preference or from the header info or from the url
  String get filename {
    String resolvedFileName =
        _preferredFilename ??
        _userPreference['preferredFilename'] ??
        "Udm-downloaded-file";
    return resolvedFileName;
  }

  /// the setter for the filename
  ///
  /// it will update the filename in the user preference
  /// Note:: We must call to get a unique name using [p.getUniqueName] to ensure we dont overwrite existing file
  set filename(String? filename) {
    _preferredFilename = p.getUniqueName(p.join(outputDir, filename));
  }

  String get absoluteFilename => p.join(outputDir, filename);

  String get outputDir =>
      _outputDir ??
      _userPreference['outputDir'] ??
      p.join(p.getDownloadDir(), "udm", p.getFileType(filename));

  DownloaderConfig({
    required String fileUrl,

    /// the path where the file will be saved, if not given then we will try to get from preference or default dir
    String? saveDir,

    /// if not given then we will try to get from header info
    String? filename,
    this.verbose = false,
    this.downloadType = DownloadType.smart,
  }) {
    if (fileUrl.isEmpty) {
      throw ArgumentError("URL cannot be empty");
    }
    url = Uri.parse(fileUrl);
    populateConfigs();

    _outputDir = saveDir;
    this.filename = filename;

    if (saveDir != null && saveDir.isNotEmpty) {
      /// this auto throws in case of error
      p.mkDirAll(saveDir);
    }

    _outputDir = saveDir;
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
    final file = File(configPath);
    if (file.existsSync()) {
      try {
        final contents = file.readAsStringSync();
        _userPreference = jsonDecode(contents) as Map<String, dynamic>;
      } catch (e) {
        // Handle corrupt JSON
        _userPreference = {};
      }
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
}
