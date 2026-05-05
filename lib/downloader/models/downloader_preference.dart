// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Configuration and strategy definitions for the UDM downloader.
///
/// This library contains the [DownloaderPreference] class and the [DownloadType]
/// enum, which together define how a file should be downloaded, where it
/// should be saved, and how progress should be reported.
library;

import 'dart:convert';
import 'dart:io';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:udm/helpers/path_helpers/path_helpers.dart';

part 'downloader_preference.freezed.dart';
part 'downloader_preference.g.dart';

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

/// by default the freezed package makes all the fields as final
///
/// this is a wrapper around a type to make it mutable for the convenience of the developer
/// and also this class provide helpful
class MutableValue<T> {
  T value;
  MutableValue(this.value);
}

typedef MutableString = MutableValue<String>;

/// A comprehensive configuration container for the [Downloader].
///
/// [DownloaderPreference] centralizes all settings related to a download operation,
/// including filesystem paths, network headers, concurrency levels, and UI
/// preferences. It supports hierarchical configuration: explicit user input
/// overrides saved preferences, which in turn override system defaults.
@freezed
abstract class DownloaderPreference with _$DownloaderPreference {
  const DownloaderPreference._();

  /// Creates a new [DownloaderPreference] with customizable settings.
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
  const factory DownloaderPreference({
    /// The directory where the downloaded file will be saved.
    ///
    /// **Note**: If null, the system's default download directory is used.
    /// **Caution**: Ensure the process has write permissions for this directory.
    /// Explicitly set output directory provided during instantiation.
    @Default(null) String? outputDir,

    /// The number of concurrent connections (threads/isolates) to use for
    /// multi-threaded downloads.
    ///
    /// Higher values can increase throughput but also increase CPU and memory
    /// overhead. Values between 8 and 12 are typically optimal.
    @Default(8) int threadCount,

    /// Explicitly set filename provided during instantiation.
    /// if not
    @Default(null) String? fileName,

    /// The strategy used for fetching the file (e.g., [DownloadType.smart]).
    @Default(DownloadType.smart) DownloadType downloadType,

    /// The interval (in milliseconds) for synchronizing progress between worker
    /// isolates and the main thread.
    ///
    /// This interval also dictates the frequency of [Downloader.timerFunction]
    /// execution. Defaults to 500ms.
    @Default(500) int progressSyncInterval,

    /// Optional HTTP headers to include in every request (e.g., User-Agent, Authorization).
    @Default({}) Map<String, String> headers,

    /// Optional cookie string to be sent with the request headers.
    @Default("") String cookie,

    /// If `true`, the system prefers the file extension resolved from server
    /// headers over any extension provided in the user's preferred filename.
    @Default(true) bool preferResolvedExtension,
  }) = _DownloaderPreference;

  factory DownloaderPreference.fromJson(Map<String, dynamic> json) =>
      _$DownloaderPreferenceFromJson(json);

  /// Resolves the absolute path to the global UDM configuration file.
  ///
  /// Respects the `UDM_CONFIG_PATH` environment variable if present; otherwise,
  /// defaults to `~/.udm/config.json`.
  static String get configPath {
    return p.join(p.getHomeDir(), ".udm", "config", "config.json");
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
}
