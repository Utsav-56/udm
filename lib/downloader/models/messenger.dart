// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Inter-isolate communication protocol for the UDM downloader.
///
/// This library defines the messaging system used to synchronize state between
/// the main isolate and worker isolates during multi-threaded downloads.
library;

import 'dart:isolate';

import 'package:udm/downloader/downloader.dart';
import 'package:udm/downloader/models/download_status.dart';
import 'package:udm/helpers/extensions/map_extension.dart';
import 'package:udm/models/range.dart';

/// Categories of messages that can be exchanged between isolates.
enum WorkerMessageType {
  /// Reports download progress and telemetry.
  progress,

  /// Reports a fatal or recoverable error in a worker.
  error,

  /// Lifecycle commands (pause, resume, cancel).
  signal,

  /// Initial connection setup to exchange [SendPort]s.
  handshake,
}

/// Control signals sent from the main isolate to worker isolates.
enum SignalType {
  /// Suspend the current data stream.
  pause,

  /// Resume a suspended data stream.
  resume,

  /// Terminate the worker and cleanup resources.
  cancel,
}

/// Base class for all messages sent between the main isolate and workers.
abstract class WorkerMessage {
  /// The category of this message.
  final WorkerMessageType type;

  /// The unique identifier of the worker isolate involved.
  final int index;

  /// Internal constructor for [WorkerMessage].
  WorkerMessage({required this.type, required this.index});

  /// Serializes specific message data into a Map.
  Map<String, dynamic> toMapSelf();

  /// Serializes the entire message, including metadata, into a Map.
  Map<String, dynamic> toMap() {
    return {...toMapSelf(), "type": type.index, "index": index};
  }

  /// Reconstructs a [WorkerMessage] from a serialized Map.
  factory WorkerMessage.fromMap(Map<String, dynamic> map) {
    map.ensureKeyExists([
      "type",
    ], "cannot determine the type of WorkerMessafge because {{key}} is missing");

    final type = WorkerMessageType.values[map["type"]];

    switch (type) {
      case WorkerMessageType.progress:
        return ProgressMessage.fromMap(map);
      case WorkerMessageType.error:
        return ErrorMessage.fromMap(map);
      case WorkerMessageType.signal:
        return SignalMessage.fromMap(map);

      case WorkerMessageType.handshake:
        return HandshakeMessage.fromMap(map);
      default:
        throw Exception("Unknown WorkerMessageType: $type");
    }
  }

  /// Parses raw data from a [ReceivePort] into a [WorkerMessage].
  factory WorkerMessage.parseFromData(dynamic data) {
    if (data is! Map) {
      throw Exception("Invalid message format : $data");
    }

    final message = data as Map<String, dynamic>;
    return WorkerMessage.fromMap(message);
  }
}

/// Message used by workers to report their current [DownloadStatus].
class ProgressMessage extends WorkerMessage {
  /// The telemetry data for this worker's chunk.
  final DownloadStatus status;

  ProgressMessage(int index, {required this.status})
    : super(type: WorkerMessageType.progress, index: index);

  @override
  Map<String, dynamic> toMapSelf() {
    return {"status": status.toMap()};
  }

  factory ProgressMessage.fromMap(Map<String, dynamic> map) {
    return ProgressMessage(map["index"], status: DownloadStatus.fromMap(map["status"]));
  }
}

/// Message used to report an error in a worker isolate.
class ErrorMessage extends WorkerMessage {
  /// Descriptive error message.
  final String message;

  /// The byte range that needs to be retried due to the error.
  final Range newRange;

  ErrorMessage(int index, {required this.message, required this.newRange})
    : super(type: WorkerMessageType.error, index: index);

  @override
  Map<String, dynamic> toMapSelf() {
    return {"message": message, "newRange": newRange.toMap()};
  }

  factory ErrorMessage.fromMap(Map<String, dynamic> map) {
    map.ensureKeyExists([
      "index",
      "message",
      "newRange",
    ], "Cannot create error message from map because {{key}} is missing");
    return ErrorMessage(
      map["index"],
      message: map["message"],
      newRange: Range.fromMap(map["newRange"]),
    );
  }
}

/// Message used to send lifecycle signals to workers.
class SignalMessage extends WorkerMessage {
  /// The type of signal to be processed.
  final SignalType signal;

  SignalMessage(int index, {required this.signal})
    : super(type: WorkerMessageType.signal, index: index);

  @override
  Map<String, dynamic> toMapSelf() {
    return {"signal": signal.index};
  }

  factory SignalMessage.fromMap(Map<String, dynamic> map) {
    map.ensureKeyExists([
      "index",
      "signal",
    ], "Cannot create signal message from map because {{key}} is missing");
    return SignalMessage(map["index"], signal: SignalType.values[map["signal"]]);
  }
}

/// Message used during the initial isolate spawn to exchange communication ports.
class HandshakeMessage extends WorkerMessage {
  /// The port through which the main isolate can send messages to this worker.
  final SendPort sendPort;

  HandshakeMessage({required this.sendPort, required super.index})
    : super(type: WorkerMessageType.handshake);

  @override
  Map<String, dynamic> toMapSelf() {
    return {"sendPort": sendPort};
  }

  factory HandshakeMessage.fromMap(Map<String, dynamic> map) {
    map.ensureKeyExists([
      "index",
      "sendPort",
    ], "Cannot create handshake message from map because {{key}} is missing");
    return HandshakeMessage(sendPort: map["sendPort"], index: map["index"]);
  }
}

/// Manages isolate-level communication for a specific worker.
///
/// The [WorkerMessenger] encapsulates the [SendPort] and [ReceivePort] logic,
/// providing a high-level API for sending progress and receiving signals
/// within a worker isolate.
class WorkerMessenger {
  /// Port provided by the main isolate for outbound messages.
  late final SendPort _sendPort;

  /// Local port for receiving inbound signals from the main isolate.
  late final ReceivePort _messagePort;

  /// Index identifying this worker in the multi-threaded pool.
  final int workerIndex;

  /// Callback executed when a [SignalMessage] is received from the main isolate.
  void Function(SignalMessage)? onSignalIn;

  /// private constructor
  WorkerMessenger._({required SendPort sendPort, required this.workerIndex}) {
    _sendPort = sendPort;
    _messagePort = ReceivePort();
  }

  /// Creates a [WorkerMessenger] for the given [index] using the provided [sendPort].
  factory WorkerMessenger.fromSendPort(SendPort sendPort, {required int index}) {
    return WorkerMessenger._(sendPort: sendPort, workerIndex: index);
  }

  /// this  is internal error on message not to be sent so we just log
  void _handleError(dynamic error) {
    print("Worker $workerIndex Encountered Unexpected Error: $error");
  }

  /// Starts the event loop to listen for inbound messages on [_messagePort].
  void startListening() {
    _messagePort.listen(
      onMessageRecieved,
      onError: _handleError,
      onDone: () {
        print("Worker $workerIndex closing messenger channel...");
        _messagePort.close();
      },
    );
  }

  /// Internal handler for raw data received on the message port.
  void onMessageRecieved(dynamic data) {
    final message = WorkerMessage.parseFromData(data);

    switch (message.type) {
      case WorkerMessageType.progress:
        break;
      case WorkerMessageType.error:
        break;
      case WorkerMessageType.signal:
        onSignalIn?.call(message as SignalMessage);
      case WorkerMessageType.handshake:
        break;
    }
  }

  /// Sends a generic [WorkerMessage] to the main isolate.
  void sendMessage(WorkerMessage message) {
    _sendPort.send(message.toMap());
  }

  /// Reports current [status] telemetry to the main isolate.
  void sendProgressToMain(DownloadStatus status) {
    sendMessage(ProgressMessage(workerIndex, status: status));
  }

  /// Reports a failure to the main isolate, providing the [range] for potential retry.
  void sendErrorToMain(Range range, String message) {
    sendMessage(ErrorMessage(workerIndex, newRange: range, message: message));
  }

  /// Initiates the handshake by sending the worker's [SendPort] to the main isolate.
  void handshake() {
    sendMessage(HandshakeMessage(sendPort: _messagePort.sendPort, index: workerIndex));
  }
}
