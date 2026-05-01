import 'package:udm/helpers/path_helpers/async/async_helpers.dart';
import 'package:udm/helpers/path_helpers/sync/sync_helper.dart';

/// This file is just an export file for all the path helper functions and classes
///
/// for actual usage and documentation refer to the individual files in the path_helpers directory

export 'sync/sync_helper.dart';
export 'async/async_helpers.dart';

/// A standard singleton class that gives access to all path and file operations,
/// both synchronously and asynchronously.
class AppPathHelper with PathHelper, PathHelperAsync {
  AppPathHelper._privateConstructor();

  static final AppPathHelper to = AppPathHelper._privateConstructor();
}

/// A standard constant for path operations
/// no need to import path package with prefix p explicitly
final AppPathHelper p = AppPathHelper.to;
