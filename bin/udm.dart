import 'dart:io';

import 'package:args/args.dart';
import 'package:udm/downloader/downloader.dart';
import 'package:udm/downloader/models/downloader_preference.dart';

const String version = '0.0.1';

/// Configures the command-line argument parser for the UDM CLI.
///
/// **Why**: Provides a consistent and user-friendly way to interact with the downloader
/// via terminal flags and options.
ArgParser buildParser() {
  return ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print this usage information.')
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addFlag('version', negatable: false, help: 'Print the tool version.');
}

void printUsage(ArgParser argParser) {
  print('Usage: dart udm.dart <flags> [arguments]');
  print(argParser.usage);
}

/// Entry point for the UDM Command Line Interface.
///
/// **Why**: Orchestrates the argument parsing, configuration loading, and downloader initiation.
/// **How**: Run via `dart bin/udm.dart` or after compiling to an executable.
void main(List<String> arguments) async {
  final config = DownloaderPreference(
    // fileName: "demo-file.zip",
    outputDir: Directory.current.path,
  );

  const demoUrl = "https://releases.ubuntu.com/26.04/ubuntu-26.04-desktop-amd64.iso";

  final manager = DownloadManager();

  await manager.enqueue(demoUrl);
}
