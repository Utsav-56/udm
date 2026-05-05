// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_type_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FileTypeEntry _$FileTypeEntryFromJson(Map<String, dynamic> json) =>
    _FileTypeEntry(
      name: json['name'] as String,
      extensions: (json['extensions'] as List<dynamic>)
          .map((e) => e as String)
          .toSet(),
      preferredSaveDir: json['preferredSaveDir'] as String,
    );

Map<String, dynamic> _$FileTypeEntryToJson(_FileTypeEntry instance) =>
    <String, dynamic>{
      'name': instance.name,
      'extensions': instance.extensions.toList(),
      'preferredSaveDir': instance.preferredSaveDir,
    };
