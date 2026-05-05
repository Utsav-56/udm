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
  'headers': instance.headers,
  'cookie': instance.cookie,
  'preferResolvedExtension': instance.preferResolvedExtension,
};

const _$DownloadTypeEnumMap = {
  DownloadType.single: 'single',
  DownloadType.smart: 'smart',
};
