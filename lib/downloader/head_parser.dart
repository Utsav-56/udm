// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Utility for parsing HTTP headers and retrieving remote file metadata.
///
/// This library provides tools to extract filenames, file sizes, and range
/// support from HTTP responses, enabling intelligent download strategy selection.
library;

import 'dart:io';

import 'package:udm/helpers/path_helpers/path_helpers.dart';
import 'package:udm/models/file_size.dart';

/// Metadata container for remote file information retrieved via HTTP headers.
///
/// [HeaderInfo] is essential for determining if a download can be multi-threaded
/// (via [supportsMultiStream]) and for pre-allocating disk space before the
/// download begins.
///
/// It is typically generated via [sendHeadRequest] during the initialization
/// phase of a [Downloader].
class HeaderInfo {
  /// The minimum file size (in bytes) required to justify a multi-threaded download.
  ///
  /// Defaults to 5MB. Files smaller than this threshold are usually faster to
  /// download using a single stream due to isolate spawning overhead.
  static const int minMultiStreamThreshold = 5 * 1024 * 1024;

  /// The suggested filename extracted from the `Content-Disposition` header.
  final String? filename;

  /// The total size of the remote file.
  final FileSize fileSize;

  /// Indicates whether the server supports HTTP Range requests.
  final bool acceptsRanges;

  /// The file extension derived from the filename or the URL path.
  final String? fileExtension;

  /// The MIME type of the remote file as reported by the `Content-Type` header.
  final String? contentType;

  /// Creates a [HeaderInfo] instance with explicit metadata values.
  const HeaderInfo({
    this.filename,
    required this.fileSize,
    required this.acceptsRanges,
    this.fileExtension,
    this.contentType,
  });

  /// Returns `true` if the remote server and file properties support multi-threaded downloading.
  ///
  /// Requires [acceptsRanges] to be true, a known [fileSize], and the size to be
  /// greater than or equal to [minMultiStreamThreshold].
  bool get supportsMultiStream =>
      acceptsRanges && fileSize.bytes != -1 && fileSize.bytes >= minMultiStreamThreshold;

  /// Factory constructor that parses [HeaderInfo] from an [HttpClientResponse].
  ///
  /// Extracts filename using regex from `Content-Disposition`, determines file size
  /// from `Content-Length`, and checks `Accept-Ranges` for multi-stream capability.
  factory HeaderInfo.fromResponse(HttpClientResponse response, Uri requestUri) {
    final headers = response.headers;

    //  Filename Parsing using Regex
    // Handles: filename="test.zip" and filename=test.zip
    String? parsedFilename;
    final contentDisposition = headers.value('content-disposition');
    if (contentDisposition != null) {
      final regExp = RegExp(
        r'filename[^;=\n]*=((["'
        '])(.*)2|([^;\n]*))',
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

/// Performs an HTTP HEAD request to retrieve file metadata, with an automatic fallback to GET.
///
/// **Rationale**: Standard HEAD requests are frequently blocked or restricted by
/// CDNs, WAFs, or cloud storage providers (e.g., AWS S3). If the HEAD request
/// fails (status >= 400 or exception), this function performs a range-limited
/// GET request (bytes 0-0) to extract the same metadata safely.
///
/// **Parameters**:
/// - [url]: The target resource URI.
/// - [client]: An optional [HttpClient]. If null, a temporary client is created
///   and disposed automatically.
/// - [logBuffer]: An optional [LogBuffer] for tracking the request process.
///
/// **Throws**:
/// - [SocketException] if the server is unreachable.
/// - [HttpException] if the fallback GET request also fails.
Future<HeaderInfo> sendHeadRequest(Uri url, [HttpClient? client]) async {
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

  try {
    // We use a GET request with a range of 0-0 if HEAD fails,
    // as some servers (like some AWS S3 configs) block HEAD requests.
    final request = await client.headUrl(url);

    // Ensure we follow redirects to get the actual file headers
    request.followRedirects = true;
    request.maxRedirects = 5;

    final response = await request.close();

    if (response.statusCode >= 400) {
      // Fallback for servers that hate HEAD requests:
      // Try a GET but only ask for the first byte.
      return await _fallbackGetHeader(url, client);
    }

    return HeaderInfo.fromResponse(response, url);
  } catch (e) {
    // If anything fails, try the fallback before giving up
    return await _fallbackGetHeader(url, client);
  } finally {
    if (isClientSelfMade) {
      try {
        client.close();
      } catch (e) {
        // Failed to close client
      }
    }
  }
}

/// Performs a partial GET request to retrieve headers when HEAD is blocked.
///
/// Requests only the first byte (`bytes=0-0`) and parses the `Content-Range`
/// header to determine the actual total file size.
Future<HeaderInfo> _fallbackGetHeader(Uri url, HttpClient client) async {
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
      return HeaderInfo(
        filename: info.filename,
        fileSize: FileSize(totalSize),
        acceptsRanges: true, // If we got a content-range, it definitely supports it
        fileExtension: info.fileExtension,
      );
    } else {
      // Failed to parse content-range
    }
  }

  return info;
}
