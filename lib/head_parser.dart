// demo url for testing
import 'dart:io';

import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/helpers/terminal_helpers/terminal_helper.dart';
import 'package:udm/models/downloader_config.dart';
import 'package:udm/models/metrics_models.dart';
import 'package:udm/helpers/path_helpers/path_helpers.dart';

const demoUrl =
    "https://drive.usercontent.google.com/download?id=1-hPM0AsfHY-8ZiiTx29PJoGEvz6tch7f&export=download&authuser=0&confirm=t&uuid=75bf507f-49fc-4d7c-bfe5-b6f0450aad20&at=ALBwUgkGsQqVRFNRfVS04eSsw_Uv:1777789454035";

/// Metadata container for remote file information retrieved via HTTP headers.
///
/// **Why**: Essential for determining if a download can be multi-threaded and for
/// allocating disk space before the download begins.
/// **How**: Generated via [sendHeadRequest] before initializing a [Downloader].
class HeaderInfo {
  /// The minimum size required to bother with multi-threading (default 5MB)
  static const int minMultiStreamThreshold = 5 * 1024 * 1024;

  final String? filename;
  final FileSize fileSize;
  final bool acceptsRanges;
  final String? fileExtension;
  final String? contentType;

  const HeaderInfo({
    this.filename,
    required this.fileSize,
    required this.acceptsRanges,
    this.fileExtension,
    this.contentType,
  });

  /// Reliable check for multi-stream support
  bool get supportsMultiStream =>
      acceptsRanges && fileSize.bytes != -1 && fileSize.bytes >= minMultiStreamThreshold;

  factory HeaderInfo.fromResponse(HttpClientResponse response, Uri requestUri) {
    final headers = response.headers;

    //  Filename Parsing using Regex
    // Handles: filename="test.zip" and filename=test.zip
    String? parsedFilename;
    final contentDisposition = headers.value('content-disposition');
    if (contentDisposition != null) {
      final regExp = RegExp(
        r'filename[^;=\n]*=((["'
        '])(.*)\2|([^;\n]*))',
      );
      final match = regExp.firstMatch(contentDisposition);
      parsedFilename = match?.group(3) ?? match?.group(4);
    }

    //  File Size (Defaults to -1 if missing or malformed)
    final contentLength = response.contentLength;

    // Range Support check
    // Some servers send 'Accept-Ranges: bytes', others don't but still work.
    // However, for a "Reliable" check, we trust the header.
    final acceptsRanges = headers.value('accept-ranges')?.toLowerCase() == 'bytes';

    //  Extension Logic
    String? extension = parsedFilename != null ? p.extension(parsedFilename) : null;
    if (extension == null || extension.isEmpty) {
      // Fallback: Try URI path
      extension = p.extension(requestUri.path);
    }

    return HeaderInfo(
      filename: p.sanitizeFilename(parsedFilename),
      fileSize: FileSize(contentLength), // -1 is handled here
      acceptsRanges: acceptsRanges,
      fileExtension: extension,
      contentType: headers.value('content-type'),
    );
  }

  @override
  String toString() =>
      "File: ${filename ?? 'Unknown'} | Size: ${fileSize.humanReadable} | Ranges: $acceptsRanges";
}

/// Performs an HTTP HEAD request (with fallback to GET) to retrieve file metadata.
///
/// **Why**: Standard HEAD requests are often blocked by CDNs or WAFs. This function
/// intelligently falls back to a range-limited GET request to guarantee metadata retrieval.
/// **How**: [client] and [logBuffer] are optional. If [client] is null, a temporary one is created and closed.
Future<HeaderInfo> sendHeadRequest(
  Uri url, [
  HttpClient? client,
  LogBuffer? logBuffer,
]) async {
  logBuffer ??= LogBuffer();

  // track if the client was self made or from param
  // in case of self made we dispose the client when request is finished
  bool isClientSelfMade = false;
  if (client == null) {
    client = HttpClient()
      ..maxConnectionsPerHost = 3
      ..connectionTimeout = const Duration(seconds: 10)
      ..idleTimeout = const Duration(seconds: 5);

    isClientSelfMade = true;
  }

  HeaderInfo info;

  try {
    logBuffer.cleanLastLinesAndPrint("Sending head request to $url");

    // We use a GET request with a range of 0-0 if HEAD fails,
    // as some servers (like some AWS S3 configs) block HEAD requests.
    final request = await client.headUrl(url);

    // Ensure we follow redirects to get the actual file headers
    request.followRedirects = true;
    request.maxRedirects = 5;

    final response = await request.close();

    if (response.statusCode >= 400) {
      logBuffer.writeWarning(
        "Head request failed with status code ${response.statusCode}",
      );

      // Fallback for servers that hate HEAD requests:
      // Try a GET but only ask for the first byte.
      return await _fallbackGetHeader(url, client, logBuffer);
    }

    return HeaderInfo.fromResponse(response, url);
  } catch (e) {
    logBuffer.writeError("Caught error when sending normal head request:: $e");
    // If anything fails, try the fallback before giving up
    return await _fallbackGetHeader(url, client, logBuffer);
  } finally {
    if (isClientSelfMade) {
      try {
        client.close();
      } catch (e) {
        logBuffer.writeError("Failed to close client");
      }
    }
  }
}

/// Fallback using a partial GET request (0-0)
Future<HeaderInfo> _fallbackGetHeader(
  Uri url,
  HttpClient client, [
  LogBuffer? logBuffer,
]) async {
  logBuffer ??= LogBuffer();

  logBuffer.writeInfo("Falling back to partial GET request");

  final request = await client.getUrl(url);
  request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-0');
  request.followRedirects = true;

  final response = await request.close();

  // Note: response.contentLength here might be '1' because we asked for bytes 0-0.
  // We check 'content-range' to get the REAL total size.
  final info = HeaderInfo.fromResponse(response, url);

  final contentRange = response.headers.value('content-range');
  if (contentRange != null) {
    // Format: bytes 0-0/1234567
    final totalSize = int.tryParse(contentRange.split('/').last);
    if (totalSize != null) {
      logBuffer.writeInfo("Got headers (Partial GET Request)");
      return HeaderInfo(
        filename: info.filename,
        fileSize: FileSize(totalSize),
        acceptsRanges: true, // If we got a content-range, it definitely supports it
        fileExtension: info.fileExtension,
      );
    } else {
      logBuffer.writeWarning(
        "Failed to parse content-range this wont support the parallel download",
      );
    }
  }

  return info;
}

/// Utility class for representing and formatting file sizes.
///
/// **Why**: Simplifies conversion between bytes, KB, MB, and GB while providing
/// a consistent human-readable string representation.
class FileSize {
  final int bytes;

  const FileSize(this.bytes);

  int get asKb => bytes ~/ 1024;
  int get asMb => bytes ~/ (1024 * 1024);
  int get asGb => bytes ~/ (1024 * 1024 * 1024);
  int get asTb => bytes ~/ (1024 * 1024 * 1024 * 1024);
  int get asPb => bytes ~/ (1024 * 1024 * 1024 * 1024 * 1024);

  String get humanReadable {
    if (bytes < 0) return "unknown size";

    if (bytes >= 1 << 30) {
      return '${(bytes / (1 << 30)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1 << 20) {
      return '${(bytes / (1 << 20)).toStringAsFixed(2)} MB';
    } else if (bytes >= 1 << 10) {
      return '${(bytes / (1 << 10)).toStringAsFixed(2)} KB';
    } else {
      return '$bytes bytes';
    }
  }
}
