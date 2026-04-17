import 'dart:io';

import 'package:args/args.dart';
import 'package:udm/downloader.dart';
import 'package:udm/head_parser.dart';
import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/models/downloader.dart';

const String version = '0.0.1';

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

void main(List<String> arguments) {
  final config = DownloaderConfig(
    fileUrl: demoUrl,
    preferredFilename: "demo-file",
    saveDir: Directory.current.path,
    verbose: false,
  );

  final downloader = Downloader(config: config);
  downloader.progressStream.listen((progress) {
    stdout.write('\rProgress: $progress%');
  });

  1001.divideIntoParts(8).debug(expectedTotal: 1001);

  // downloader.startDownload();
}
