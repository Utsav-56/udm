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
import 'package:udm/downloader/downloader.dart';
import 'package:udm/downloader/head_parser.dart';
import 'package:udm/downloader/models/downloader_preference.dart';
import 'package:udm/downloader/models/file_type_entry.dart';
import 'package:udm/downloader/models/manager_preferences.dart';

/// Represents a queued download operation awaiting execution.
///
/// Holds the target [url] and [config] while exposing a [completer] that
/// will resolve with the spawned [Downloader] instance once processing begins.
class DownloadTask {
  /// The remote URL of the file to be downloaded.
  final String url;

  /// Configuration settings for this specific download.
  final DownloaderPreference config;

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
  /// The preferences of the download manager.
  late ManagerPreferences preferences;
  late FileTypePreference typePreference;

  /// Creates a [DownloadManager].
  ///
  /// If [preferences] is not provided, it defaults to [ManagerPreferences.fromFile].
  DownloadManager({ManagerPreferences? preferences}) {
    this.preferences = preferences ?? ManagerPreferences.fromFile();
    typePreference = FileTypePreference.fromFile();
  }

  /// refreshes the preferences
  void refreshPreferences() {
    preferences = ManagerPreferences.fromFile();
    typePreference = FileTypePreference.fromFile();
  }

  /// A registry of all instantiated downloaders, keyed by their unique timestamped ID.
  ///
  /// This map allows external components to signal specific downloaders (e.g., pause, resume, cancel).
  final Map<String, Downloader> spawnedDownloaders = {};

  /// The internal queue of pending [DownloadTask] instances.
  final List<DownloadTask> _queue = [];

  /// The current number of active downloads being processed.
  int _activeDownloads = 0;

  /// Returns the maximum number of downloads allowed to run concurrently.
  int get maxConcurrentDownloads => preferences.maxConcurrentDownloads;

  /// Adds a new download operation to the queue.
  ///
  /// If the number of active downloads is less than [maxConcurrentDownloads],
  /// the download starts immediately. Otherwise, it waits in the queue.
  ///
  /// Returns a [Future] that completes with the instantiated [Downloader]
  /// once the task starts executing.
  Future<Downloader> enqueue(String url, {DownloaderPreference? config}) {
    final task = DownloadTask(url: url, config: config ?? preferences.downloaderConfig);
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
  Future<Downloader> _spawnDownloader(String url, DownloaderPreference config) async {
    // MultiStreamDownload now handles initialization (HEAD request) and smart fallback internally
    return MultiStreamDownload(url: url, config: config);
  }
}
