// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Configuration and persistence for global download manager settings.
///
/// This library provides the [ManagerPreferences] class, which uses `freezed`
/// for immutability and `json_serializable` for automated disk persistence.
library;

import 'dart:convert';
import 'dart:io';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:udm/downloader/models/downloader_preference.dart';
import 'package:udm/helpers/path_helpers/path_helpers.dart' as path_helper;

part 'manager_preferences.freezed.dart';
part 'manager_preferences.g.dart';

/// The global preferences for the [DownloadManager].
///
/// This class defines how the manager should behave globally, including
/// concurrency limits, default HTTP headers, and filesystem paths.
@freezed
abstract class ManagerPreferences with _$ManagerPreferences {
  /// Internal constructor for adding custom methods and getters.
  const ManagerPreferences._();

  /// Creates a new [ManagerPreferences] instance.
  ///
  /// - [maxConcurrentDownloads]: Max number of active downloads in the queue.
  /// - [threadCount]: Default number of threads for multi-stream downloads.
  /// - [userAgent]: The User-Agent string for HTTP requests.
  /// - [customHeaders]: Global headers to include in all requests.
  /// - [cookie]: Global cookie string.
  /// - [retryOnFailure]: Whether to automatically retry failed downloads.
  /// - [maxRetries]: Max number of retry attempts.
  /// - [timeout]: HTTP connection timeout in seconds.
  /// - [maxConnectionsPerHost]: Max connections allowed per host.
  /// - [idleTimeout]: HTTP idle timeout in seconds.
  /// - [followRedirects]: Whether to follow HTTP redirects.
  /// - [ignoreBadCertificate]: Whether to ignore SSL certificate errors.
  /// - [savePath]: Default directory for saved downloads.
  /// - [tempPath]: Directory for temporary download parts.
  /// - [deleteFileOnCancel]: Whether to delete partial files when a download is canceled.
  /// - [preferServerFileExtension]: Whether to prioritize server-provided extensions.
  /// - [maxSpeed]: Maximum download speed (not yet implemented in core).
  /// - [minSpeed]: Minimum download speed (not yet implemented in core).
  const factory ManagerPreferences({
    @Default(4) int maxConcurrentDownloads,
    @Default(8) int threadCount,
    @Default(
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3",
    )
    String userAgent,
    @Default({}) Map<String, String> customHeaders,
    @Default("") String cookie,
    @Default(true) bool retryOnFailure,
    @Default(3) int maxRetries,
    @Default(10) int timeout,
    @Default(4) int maxConnectionsPerHost,
    @Default(5) int idleTimeout,
    @Default(true) bool followRedirects,
    @Default(false) bool ignoreBadCertificate,
    @Default("") String savePath,
    @Default("") String tempPath,
    @Default(false) bool deleteFileOnCancel,
    @Default(true) bool preferServerFileExtension,
    @Default(0) int maxSpeed,
    @Default(0) int minSpeed,
  }) = _ManagerPreferences;

  /// Creates a [ManagerPreferences] from a JSON map.
  factory ManagerPreferences.fromJson(Map<String, dynamic> json) =>
      _$ManagerPreferencesFromJson(json);

  /// Generates a [DownloaderPreference] based on the current preferences.
  DownloaderPreference get downloaderConfig => DownloaderPreference(
    cookie: cookie,
    downloadType: DownloadType.smart,
    headers: customHeaders,
    threadCount: threadCount,
    outputDir: savePath,
    preferResolvedExtension: preferServerFileExtension,
  );

  /// The default absolute path where preferences are stored on disk.
  static String get prefFilePath =>
      p.join(path_helper.p.getHomeDir(), '.udm', 'config', 'prefs.json');

  /// Ensures the configuration directory and file exist, initializing with defaults if necessary.
  static void _ensurePrefsFile() {
    final file = File(prefFilePath);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
      const defaultPrefs = ManagerPreferences();
      file.writeAsStringSync(
        const JsonEncoder.withIndent("  ").convert(defaultPrefs.toJson()),
      );
    }
  }

  /// Loads preferences from the [prefFilePath].
  ///
  /// If the file does not exist, returns a default [ManagerPreferences] instance.
  factory ManagerPreferences.fromFile() {
    final file = File(prefFilePath);
    if (!file.existsSync()) {
      return const ManagerPreferences();
    }

    try {
      final jsonString = file.readAsStringSync();
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return ManagerPreferences.fromJson(jsonMap);
    } catch (e) {
      // Fallback to defaults on corruption
      return const ManagerPreferences();
    }
  }

  /// Persists the current preferences to [prefFilePath].
  void saveToFile() {
    _ensurePrefsFile();
    final file = File(prefFilePath);
    file.writeAsStringSync(const JsonEncoder.withIndent("  ").convert(toJson()));
  }
}
