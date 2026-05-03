// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Unified gateway for filesystem and path operations.
///
/// This library provides the [AppPathHelper] class and a global instance [p],
/// combining synchronous and asynchronous utilities for managing files and paths.
library;

import 'package:udm/helpers/path_helpers/async/async_helpers.dart';
import 'package:udm/helpers/path_helpers/sync/sync_helper.dart';

export 'sync/sync_helper.dart';
export 'async/async_helpers.dart';

/// A centralized orchestrator for cross-platform path and file operations.
///
/// [AppPathHelper] mixes in both [PathHelper] (synchronous) and [PathHelperAsync]
/// (asynchronous) to provide a comprehensive API for filesystem interactions.
class AppPathHelper with PathHelper, PathHelperAsync {
  AppPathHelper._privateConstructor();

  /// The singleton instance of [AppPathHelper].
  static final AppPathHelper to = AppPathHelper._privateConstructor();
}

/// Global shortcut for accessing [AppPathHelper] utilities.
///
/// Use [p] for all path manipulations and file I/O within the project to ensure
/// consistent cross-platform behavior.
final AppPathHelper p = AppPathHelper.to;
