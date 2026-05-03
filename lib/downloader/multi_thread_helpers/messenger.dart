import 'dart:isolate';

import 'package:udm/downloader/downloader.dart';
import 'package:udm/helpers/extensions/int_extensions.dart';
import 'package:udm/helpers/extensions/map_extension.dart';

enum WorkerMessageType { progress, error, signal, handshake }

enum SignalType { pause, resume, cancel }

abstract class WorkerMessage {
  final WorkerMessageType type;
  final int index;

  WorkerMessage({required this.type, required this.index});

  Map<String, dynamic> toMapSelf();

  Map<String, dynamic> toMap() {
    return {...toMapSelf(), "type": type.index, "index": index};
  }

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

  /// this parses the message from raw data sent by the port
  /// it is universal can be used by any class to parse the message
  factory WorkerMessage.parseFromData(dynamic data) {
    if (data is! Map) {
      throw Exception("Invalid message format : $data");
    }

    final message = data as Map<String, dynamic>;
    return WorkerMessage.fromMap(message);
  }
}

class ProgressMessage extends WorkerMessage {
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

class ErrorMessage extends WorkerMessage {
  final String message;

  /// in case of errror we send back the index and updated range of the chunk
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

class SignalMessage extends WorkerMessage {
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

class HandshakeMessage extends WorkerMessage {
  final SendPort sendPort;

  HandshakeMessage({required this.sendPort, required int index})
    : super(type: WorkerMessageType.handshake, index: index);

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

/// class that will be used to send the message to main isolate
class WorkerMessenger {
  /// the port that was sent by the main isolate during the intialization of worker
  late final SendPort _sendPort;

  /// this is the internal port of the current worker which is used to communicate with the main isolate
  /// we make the messagePort as null initially and later in start method we pass the _receivePort
  late final ReceivePort _messagePort;

  final int workerIndex;

  // CALLBACK FUNCTIONS INCOMING FROM MAIN
  // MAIN CANN ONLY SEND THE SIGNALS NOTHING ELSE
  void Function(SignalMessage)? onSignalIn;

  /// private constructor
  WorkerMessenger._({required SendPort sendPort, required this.workerIndex}) {
    _sendPort = sendPort;
    _messagePort = ReceivePort();
  }

  /// factory to create a new instance of WorkerMessenger
  factory WorkerMessenger.fromSendPort(SendPort sendPort, {required int index}) {
    return WorkerMessenger._(sendPort: sendPort, workerIndex: index);
  }

  /// this  is internal error on message not to be sent so we just log
  void _handleError(dynamic error) {
    print("Worker $workerIndex Encountered Unexpected Error: $error");
  }

  /// listens for the messages from the main isolate
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

  void sendMessage(WorkerMessage message) {
    _sendPort.send(message.toMap());
  }

  void sendProgressToMain(DownloadStatus status) {
    sendMessage(ProgressMessage(workerIndex, status: status));
  }

  void sendErrorToMain(Range range, String message) {
    sendMessage(ErrorMessage(workerIndex, newRange: range, message: message));
  }

  /// passes the recive port of current worker to the main isolate as a handshake for messages
  void handshake() {
    sendMessage(HandshakeMessage(sendPort: _messagePort.sendPort, index: workerIndex));
  }
}
