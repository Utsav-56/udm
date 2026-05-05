// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_type_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileTypeEntry {

 String get name; Set<String> get extensions; String get preferredSaveDir;
/// Create a copy of FileTypeEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileTypeEntryCopyWith<FileTypeEntry> get copyWith => _$FileTypeEntryCopyWithImpl<FileTypeEntry>(this as FileTypeEntry, _$identity);

  /// Serializes this FileTypeEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileTypeEntry&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.extensions, extensions)&&(identical(other.preferredSaveDir, preferredSaveDir) || other.preferredSaveDir == preferredSaveDir));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(extensions),preferredSaveDir);

@override
String toString() {
  return 'FileTypeEntry(name: $name, extensions: $extensions, preferredSaveDir: $preferredSaveDir)';
}


}

/// @nodoc
abstract mixin class $FileTypeEntryCopyWith<$Res>  {
  factory $FileTypeEntryCopyWith(FileTypeEntry value, $Res Function(FileTypeEntry) _then) = _$FileTypeEntryCopyWithImpl;
@useResult
$Res call({
 String name, Set<String> extensions, String preferredSaveDir
});




}
/// @nodoc
class _$FileTypeEntryCopyWithImpl<$Res>
    implements $FileTypeEntryCopyWith<$Res> {
  _$FileTypeEntryCopyWithImpl(this._self, this._then);

  final FileTypeEntry _self;
  final $Res Function(FileTypeEntry) _then;

/// Create a copy of FileTypeEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? extensions = null,Object? preferredSaveDir = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,extensions: null == extensions ? _self.extensions : extensions // ignore: cast_nullable_to_non_nullable
as Set<String>,preferredSaveDir: null == preferredSaveDir ? _self.preferredSaveDir : preferredSaveDir // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FileTypeEntry].
extension FileTypeEntryPatterns on FileTypeEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileTypeEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileTypeEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileTypeEntry value)  $default,){
final _that = this;
switch (_that) {
case _FileTypeEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileTypeEntry value)?  $default,){
final _that = this;
switch (_that) {
case _FileTypeEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  Set<String> extensions,  String preferredSaveDir)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileTypeEntry() when $default != null:
return $default(_that.name,_that.extensions,_that.preferredSaveDir);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  Set<String> extensions,  String preferredSaveDir)  $default,) {final _that = this;
switch (_that) {
case _FileTypeEntry():
return $default(_that.name,_that.extensions,_that.preferredSaveDir);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  Set<String> extensions,  String preferredSaveDir)?  $default,) {final _that = this;
switch (_that) {
case _FileTypeEntry() when $default != null:
return $default(_that.name,_that.extensions,_that.preferredSaveDir);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileTypeEntry implements FileTypeEntry {
  const _FileTypeEntry({required this.name, required final  Set<String> extensions, required this.preferredSaveDir}): _extensions = extensions;
  factory _FileTypeEntry.fromJson(Map<String, dynamic> json) => _$FileTypeEntryFromJson(json);

@override final  String name;
 final  Set<String> _extensions;
@override Set<String> get extensions {
  if (_extensions is EqualUnmodifiableSetView) return _extensions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_extensions);
}

@override final  String preferredSaveDir;

/// Create a copy of FileTypeEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileTypeEntryCopyWith<_FileTypeEntry> get copyWith => __$FileTypeEntryCopyWithImpl<_FileTypeEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileTypeEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileTypeEntry&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._extensions, _extensions)&&(identical(other.preferredSaveDir, preferredSaveDir) || other.preferredSaveDir == preferredSaveDir));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_extensions),preferredSaveDir);

@override
String toString() {
  return 'FileTypeEntry(name: $name, extensions: $extensions, preferredSaveDir: $preferredSaveDir)';
}


}

/// @nodoc
abstract mixin class _$FileTypeEntryCopyWith<$Res> implements $FileTypeEntryCopyWith<$Res> {
  factory _$FileTypeEntryCopyWith(_FileTypeEntry value, $Res Function(_FileTypeEntry) _then) = __$FileTypeEntryCopyWithImpl;
@override @useResult
$Res call({
 String name, Set<String> extensions, String preferredSaveDir
});




}
/// @nodoc
class __$FileTypeEntryCopyWithImpl<$Res>
    implements _$FileTypeEntryCopyWith<$Res> {
  __$FileTypeEntryCopyWithImpl(this._self, this._then);

  final _FileTypeEntry _self;
  final $Res Function(_FileTypeEntry) _then;

/// Create a copy of FileTypeEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? extensions = null,Object? preferredSaveDir = null,}) {
  return _then(_FileTypeEntry(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,extensions: null == extensions ? _self._extensions : extensions // ignore: cast_nullable_to_non_nullable
as Set<String>,preferredSaveDir: null == preferredSaveDir ? _self.preferredSaveDir : preferredSaveDir // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
