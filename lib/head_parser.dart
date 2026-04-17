// demo url for testing
import 'dart:io';

import 'package:udm/app_path_helper.dart';
import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/models/downloader.dart';

const demoUrl =
    "https://drive.usercontent.google.com/download?id=1d1EBTcLHYQiv93O4nyBBjbK_Wc-2f5qX&export=download&authuser=0&confirm=t&uuid=dd710d80-2b80-47e6-9768-41730efed5c1&at=ALBwUgkj_7i0p2ZZsknUP43DWlJS:1776241352545";

class HeaderInfo {
  final String? filename;
  final FileSize fileSize;
  final bool acceptsRanges;
  final String? fileExtension;

  const HeaderInfo({
    required this.filename,
    required this.fileSize,
    required this.acceptsRanges,
    this.fileExtension,
  });

  bool get supportsMultiStream =>
      acceptsRanges && (fileSize.bytes > 1.mb); // min threshold for multi-stream download

  @override
  String toString() {
    return "Filename: $filename | File Size: ${fileSize.humanReadable} | Accepts Ranges: $acceptsRanges'";
  }

  factory HeaderInfo.fromResponse(HttpClientResponse response) {
    final filename = response.headers
        .value('content-disposition')
        ?.split('filename=')
        .last
        .replaceAll('"', '');
    final contentLength = response.contentLength;
    final acceptsRanges = response.headers.value('accept-ranges') == 'bytes';

    /// try to get file extension from filename if possible
    String? fileExtension = p.extension(filename);

    // if we still don't have file extension try to get it from url
    if (fileExtension == null || fileExtension.isEmpty) {
      /// Split the url and get the last part which is usually the filename with extension
      final urlPath = Uri.parse(demoUrl).path;
      final urlFilename = p.basename(urlPath);

      fileExtension = p.extension(urlFilename);
    }

    /// if we still don't have file extension then the file dont have a extension we assume
    /// we can technically query the content-type header and map it to an extension but for simplicity we will just leave it as null

    return HeaderInfo(
      filename: p.sanitizeFilename(filename),
      fileSize: FileSize(contentLength),
      acceptsRanges: acceptsRanges,
      fileExtension: fileExtension,
    );
  }
}

Future<HeaderInfo> sendHeadRequest(HttpClient client, Uri url) async {
  final request = await client.headUrl(url);

  final HttpClientResponse response = await request.close();
  return HeaderInfo.fromResponse(response);
}
