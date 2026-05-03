import 'dart:io';

import 'package:args/args.dart';
import 'package:udm/downloader.dart';
import 'package:udm/downloader/downloader.dart';
import 'package:udm/downloader/multi_stream_download.dart';
import 'package:udm/downloader/single_stream_downloader.dart';
import 'package:udm/head_parser.dart';
import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/models/downloader_config.dart';

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
    filename: "demo-file.zip",
    saveDir: Directory.current.path,
    verbose: true,
  );

  final downloader = MultiStreamDownload(config: config);

  // 1001.divideIntoParts(8).debug(expectedTotal: 1001);

  downloader.start();
}
