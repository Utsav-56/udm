// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manager_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ManagerPreferences _$ManagerPreferencesFromJson(
  Map<String, dynamic> json,
) => _ManagerPreferences(
  maxConcurrentDownloads:
      (json['maxConcurrentDownloads'] as num?)?.toInt() ?? 4,
  threadCount: (json['threadCount'] as num?)?.toInt() ?? 8,
  userAgent:
      json['userAgent'] as String? ??
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3",
  customHeaders:
      (json['customHeaders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  cookie: json['cookie'] as String? ?? "",
  retryOnFailure: json['retryOnFailure'] as bool? ?? true,
  maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 3,
  timeout: (json['timeout'] as num?)?.toInt() ?? 10,
  maxConnectionsPerHost: (json['maxConnectionsPerHost'] as num?)?.toInt() ?? 4,
  idleTimeout: (json['idleTimeout'] as num?)?.toInt() ?? 5,
  followRedirects: json['followRedirects'] as bool? ?? true,
  ignoreBadCertificate: json['ignoreBadCertificate'] as bool? ?? false,
  savePath: json['savePath'] as String? ?? "",
  tempPath: json['tempPath'] as String? ?? "",
  deleteFileOnCancel: json['deleteFileOnCancel'] as bool? ?? false,
  preferServerFileExtension: json['preferServerFileExtension'] as bool? ?? true,
  maxSpeed: (json['maxSpeed'] as num?)?.toInt() ?? 0,
  minSpeed: (json['minSpeed'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ManagerPreferencesToJson(_ManagerPreferences instance) =>
    <String, dynamic>{
      'maxConcurrentDownloads': instance.maxConcurrentDownloads,
      'threadCount': instance.threadCount,
      'userAgent': instance.userAgent,
      'customHeaders': instance.customHeaders,
      'cookie': instance.cookie,
      'retryOnFailure': instance.retryOnFailure,
      'maxRetries': instance.maxRetries,
      'timeout': instance.timeout,
      'maxConnectionsPerHost': instance.maxConnectionsPerHost,
      'idleTimeout': instance.idleTimeout,
      'followRedirects': instance.followRedirects,
      'ignoreBadCertificate': instance.ignoreBadCertificate,
      'savePath': instance.savePath,
      'tempPath': instance.tempPath,
      'deleteFileOnCancel': instance.deleteFileOnCancel,
      'preferServerFileExtension': instance.preferServerFileExtension,
      'maxSpeed': instance.maxSpeed,
      'minSpeed': instance.minSpeed,
    };
