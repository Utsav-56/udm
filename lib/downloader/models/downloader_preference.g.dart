// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloader_preference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DownloaderPreference _$DownloaderPreferenceFromJson(
  Map<String, dynamic> json,
) => _DownloaderPreference(
  outputDir: json['outputDir'] as String? ?? null,
  threadCount: (json['threadCount'] as num?)?.toInt() ?? 8,
  fileName: json['fileName'] as String? ?? null,
  downloadType:
      $enumDecodeNullable(_$DownloadTypeEnumMap, json['downloadType']) ??
      DownloadType.smart,
  progressSyncInterval: (json['progressSyncInterval'] as num?)?.toInt() ?? 500,
  timeout: (json['timeout'] as num?)?.toInt() ?? 10,
  idleTimeout: (json['idleTimeout'] as num?)?.toInt() ?? 5,
  userAgent:
      json['userAgent'] as String? ??
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3",
  headers:
      (json['headers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  cookie: json['cookie'] as String? ?? "",
  preferResolvedExtension: json['preferResolvedExtension'] as bool? ?? true,
);

Map<String, dynamic> _$DownloaderPreferenceToJson(
  _DownloaderPreference instance,
) => <String, dynamic>{
  'outputDir': instance.outputDir,
  'threadCount': instance.threadCount,
  'fileName': instance.fileName,
  'downloadType': _$DownloadTypeEnumMap[instance.downloadType]!,
  'progressSyncInterval': instance.progressSyncInterval,
  'timeout': instance.timeout,
  'idleTimeout': instance.idleTimeout,
  'userAgent': instance.userAgent,
  'headers': instance.headers,
  'cookie': instance.cookie,
  'preferResolvedExtension': instance.preferResolvedExtension,
};

const _$DownloadTypeEnumMap = {
  DownloadType.single: 'single',
  DownloadType.smart: 'smart',
};
