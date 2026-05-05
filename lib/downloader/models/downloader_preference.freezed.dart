// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'downloader_preference.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloaderPreference {

/// The directory where the downloaded file will be saved.
///
/// **Note**: If null, the system's default download directory is used.
/// **Caution**: Ensure the process has write permissions for this directory.
/// Explicitly set output directory provided during instantiation.
 String? get outputDir;/// The number of concurrent connections (threads/isolates) to use for
/// multi-threaded downloads.
///
/// Higher values can increase throughput but also increase CPU and memory
/// overhead. Values between 8 and 12 are typically optimal.
 int get threadCount;/// Explicitly set filename provided during instantiation.
/// if not
 String? get fileName;/// The strategy used for fetching the file (e.g., [DownloadType.smart]).
 DownloadType get downloadType;/// The interval (in milliseconds) for synchronizing progress between worker
/// isolates and the main thread.
///
/// This interval also dictates the frequency of [Downloader.timerFunction]
/// execution. Defaults to 500ms.
 int get progressSyncInterval; int get timeout; int get idleTimeout; String get userAgent;/// Optional HTTP headers to include in every request (e.g., User-Agent, Authorization).
 Map<String, String> get headers;/// Optional cookie string to be sent with the request headers.
 String get cookie;/// If `true`, the system prefers the file extension resolved from server
/// headers over any extension provided in the user's preferred filename.
 bool get preferResolvedExtension;
/// Create a copy of DownloaderPreference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloaderPreferenceCopyWith<DownloaderPreference> get copyWith => _$DownloaderPreferenceCopyWithImpl<DownloaderPreference>(this as DownloaderPreference, _$identity);

  /// Serializes this DownloaderPreference to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloaderPreference&&(identical(other.outputDir, outputDir) || other.outputDir == outputDir)&&(identical(other.threadCount, threadCount) || other.threadCount == threadCount)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.downloadType, downloadType) || other.downloadType == downloadType)&&(identical(other.progressSyncInterval, progressSyncInterval) || other.progressSyncInterval == progressSyncInterval)&&(identical(other.timeout, timeout) || other.timeout == timeout)&&(identical(other.idleTimeout, idleTimeout) || other.idleTimeout == idleTimeout)&&(identical(other.userAgent, userAgent) || other.userAgent == userAgent)&&const DeepCollectionEquality().equals(other.headers, headers)&&(identical(other.cookie, cookie) || other.cookie == cookie)&&(identical(other.preferResolvedExtension, preferResolvedExtension) || other.preferResolvedExtension == preferResolvedExtension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,outputDir,threadCount,fileName,downloadType,progressSyncInterval,timeout,idleTimeout,userAgent,const DeepCollectionEquality().hash(headers),cookie,preferResolvedExtension);

@override
String toString() {
  return 'DownloaderPreference(outputDir: $outputDir, threadCount: $threadCount, fileName: $fileName, downloadType: $downloadType, progressSyncInterval: $progressSyncInterval, timeout: $timeout, idleTimeout: $idleTimeout, userAgent: $userAgent, headers: $headers, cookie: $cookie, preferResolvedExtension: $preferResolvedExtension)';
}


}

/// @nodoc
abstract mixin class $DownloaderPreferenceCopyWith<$Res>  {
  factory $DownloaderPreferenceCopyWith(DownloaderPreference value, $Res Function(DownloaderPreference) _then) = _$DownloaderPreferenceCopyWithImpl;
@useResult
$Res call({
 String? outputDir, int threadCount, String? fileName, DownloadType downloadType, int progressSyncInterval, int timeout, int idleTimeout, String userAgent, Map<String, String> headers, String cookie, bool preferResolvedExtension
});




}
/// @nodoc
class _$DownloaderPreferenceCopyWithImpl<$Res>
    implements $DownloaderPreferenceCopyWith<$Res> {
  _$DownloaderPreferenceCopyWithImpl(this._self, this._then);

  final DownloaderPreference _self;
  final $Res Function(DownloaderPreference) _then;

/// Create a copy of DownloaderPreference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? outputDir = freezed,Object? threadCount = null,Object? fileName = freezed,Object? downloadType = null,Object? progressSyncInterval = null,Object? timeout = null,Object? idleTimeout = null,Object? userAgent = null,Object? headers = null,Object? cookie = null,Object? preferResolvedExtension = null,}) {
  return _then(_self.copyWith(
outputDir: freezed == outputDir ? _self.outputDir : outputDir // ignore: cast_nullable_to_non_nullable
as String?,threadCount: null == threadCount ? _self.threadCount : threadCount // ignore: cast_nullable_to_non_nullable
as int,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,downloadType: null == downloadType ? _self.downloadType : downloadType // ignore: cast_nullable_to_non_nullable
as DownloadType,progressSyncInterval: null == progressSyncInterval ? _self.progressSyncInterval : progressSyncInterval // ignore: cast_nullable_to_non_nullable
as int,timeout: null == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as int,idleTimeout: null == idleTimeout ? _self.idleTimeout : idleTimeout // ignore: cast_nullable_to_non_nullable
as int,userAgent: null == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String,headers: null == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,cookie: null == cookie ? _self.cookie : cookie // ignore: cast_nullable_to_non_nullable
as String,preferResolvedExtension: null == preferResolvedExtension ? _self.preferResolvedExtension : preferResolvedExtension // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloaderPreference].
extension DownloaderPreferencePatterns on DownloaderPreference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloaderPreference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloaderPreference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloaderPreference value)  $default,){
final _that = this;
switch (_that) {
case _DownloaderPreference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloaderPreference value)?  $default,){
final _that = this;
switch (_that) {
case _DownloaderPreference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? outputDir,  int threadCount,  String? fileName,  DownloadType downloadType,  int progressSyncInterval,  int timeout,  int idleTimeout,  String userAgent,  Map<String, String> headers,  String cookie,  bool preferResolvedExtension)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloaderPreference() when $default != null:
return $default(_that.outputDir,_that.threadCount,_that.fileName,_that.downloadType,_that.progressSyncInterval,_that.timeout,_that.idleTimeout,_that.userAgent,_that.headers,_that.cookie,_that.preferResolvedExtension);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? outputDir,  int threadCount,  String? fileName,  DownloadType downloadType,  int progressSyncInterval,  int timeout,  int idleTimeout,  String userAgent,  Map<String, String> headers,  String cookie,  bool preferResolvedExtension)  $default,) {final _that = this;
switch (_that) {
case _DownloaderPreference():
return $default(_that.outputDir,_that.threadCount,_that.fileName,_that.downloadType,_that.progressSyncInterval,_that.timeout,_that.idleTimeout,_that.userAgent,_that.headers,_that.cookie,_that.preferResolvedExtension);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? outputDir,  int threadCount,  String? fileName,  DownloadType downloadType,  int progressSyncInterval,  int timeout,  int idleTimeout,  String userAgent,  Map<String, String> headers,  String cookie,  bool preferResolvedExtension)?  $default,) {final _that = this;
switch (_that) {
case _DownloaderPreference() when $default != null:
return $default(_that.outputDir,_that.threadCount,_that.fileName,_that.downloadType,_that.progressSyncInterval,_that.timeout,_that.idleTimeout,_that.userAgent,_that.headers,_that.cookie,_that.preferResolvedExtension);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloaderPreference extends DownloaderPreference {
  const _DownloaderPreference({this.outputDir = null, this.threadCount = 8, this.fileName = null, this.downloadType = DownloadType.smart, this.progressSyncInterval = 500, this.timeout = 10, this.idleTimeout = 5, this.userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3", final  Map<String, String> headers = const {}, this.cookie = "", this.preferResolvedExtension = true}): _headers = headers,super._();
  factory _DownloaderPreference.fromJson(Map<String, dynamic> json) => _$DownloaderPreferenceFromJson(json);

/// The directory where the downloaded file will be saved.
///
/// **Note**: If null, the system's default download directory is used.
/// **Caution**: Ensure the process has write permissions for this directory.
/// Explicitly set output directory provided during instantiation.
@override@JsonKey() final  String? outputDir;
/// The number of concurrent connections (threads/isolates) to use for
/// multi-threaded downloads.
///
/// Higher values can increase throughput but also increase CPU and memory
/// overhead. Values between 8 and 12 are typically optimal.
@override@JsonKey() final  int threadCount;
/// Explicitly set filename provided during instantiation.
/// if not
@override@JsonKey() final  String? fileName;
/// The strategy used for fetching the file (e.g., [DownloadType.smart]).
@override@JsonKey() final  DownloadType downloadType;
/// The interval (in milliseconds) for synchronizing progress between worker
/// isolates and the main thread.
///
/// This interval also dictates the frequency of [Downloader.timerFunction]
/// execution. Defaults to 500ms.
@override@JsonKey() final  int progressSyncInterval;
@override@JsonKey() final  int timeout;
@override@JsonKey() final  int idleTimeout;
@override@JsonKey() final  String userAgent;
/// Optional HTTP headers to include in every request (e.g., User-Agent, Authorization).
 final  Map<String, String> _headers;
/// Optional HTTP headers to include in every request (e.g., User-Agent, Authorization).
@override@JsonKey() Map<String, String> get headers {
  if (_headers is EqualUnmodifiableMapView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_headers);
}

/// Optional cookie string to be sent with the request headers.
@override@JsonKey() final  String cookie;
/// If `true`, the system prefers the file extension resolved from server
/// headers over any extension provided in the user's preferred filename.
@override@JsonKey() final  bool preferResolvedExtension;

/// Create a copy of DownloaderPreference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloaderPreferenceCopyWith<_DownloaderPreference> get copyWith => __$DownloaderPreferenceCopyWithImpl<_DownloaderPreference>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloaderPreferenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloaderPreference&&(identical(other.outputDir, outputDir) || other.outputDir == outputDir)&&(identical(other.threadCount, threadCount) || other.threadCount == threadCount)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.downloadType, downloadType) || other.downloadType == downloadType)&&(identical(other.progressSyncInterval, progressSyncInterval) || other.progressSyncInterval == progressSyncInterval)&&(identical(other.timeout, timeout) || other.timeout == timeout)&&(identical(other.idleTimeout, idleTimeout) || other.idleTimeout == idleTimeout)&&(identical(other.userAgent, userAgent) || other.userAgent == userAgent)&&const DeepCollectionEquality().equals(other._headers, _headers)&&(identical(other.cookie, cookie) || other.cookie == cookie)&&(identical(other.preferResolvedExtension, preferResolvedExtension) || other.preferResolvedExtension == preferResolvedExtension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,outputDir,threadCount,fileName,downloadType,progressSyncInterval,timeout,idleTimeout,userAgent,const DeepCollectionEquality().hash(_headers),cookie,preferResolvedExtension);

@override
String toString() {
  return 'DownloaderPreference(outputDir: $outputDir, threadCount: $threadCount, fileName: $fileName, downloadType: $downloadType, progressSyncInterval: $progressSyncInterval, timeout: $timeout, idleTimeout: $idleTimeout, userAgent: $userAgent, headers: $headers, cookie: $cookie, preferResolvedExtension: $preferResolvedExtension)';
}


}

/// @nodoc
abstract mixin class _$DownloaderPreferenceCopyWith<$Res> implements $DownloaderPreferenceCopyWith<$Res> {
  factory _$DownloaderPreferenceCopyWith(_DownloaderPreference value, $Res Function(_DownloaderPreference) _then) = __$DownloaderPreferenceCopyWithImpl;
@override @useResult
$Res call({
 String? outputDir, int threadCount, String? fileName, DownloadType downloadType, int progressSyncInterval, int timeout, int idleTimeout, String userAgent, Map<String, String> headers, String cookie, bool preferResolvedExtension
});




}
/// @nodoc
class __$DownloaderPreferenceCopyWithImpl<$Res>
    implements _$DownloaderPreferenceCopyWith<$Res> {
  __$DownloaderPreferenceCopyWithImpl(this._self, this._then);

  final _DownloaderPreference _self;
  final $Res Function(_DownloaderPreference) _then;

/// Create a copy of DownloaderPreference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? outputDir = freezed,Object? threadCount = null,Object? fileName = freezed,Object? downloadType = null,Object? progressSyncInterval = null,Object? timeout = null,Object? idleTimeout = null,Object? userAgent = null,Object? headers = null,Object? cookie = null,Object? preferResolvedExtension = null,}) {
  return _then(_DownloaderPreference(
outputDir: freezed == outputDir ? _self.outputDir : outputDir // ignore: cast_nullable_to_non_nullable
as String?,threadCount: null == threadCount ? _self.threadCount : threadCount // ignore: cast_nullable_to_non_nullable
as int,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,downloadType: null == downloadType ? _self.downloadType : downloadType // ignore: cast_nullable_to_non_nullable
as DownloadType,progressSyncInterval: null == progressSyncInterval ? _self.progressSyncInterval : progressSyncInterval // ignore: cast_nullable_to_non_nullable
as int,timeout: null == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as int,idleTimeout: null == idleTimeout ? _self.idleTimeout : idleTimeout // ignore: cast_nullable_to_non_nullable
as int,userAgent: null == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String,headers: null == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,cookie: null == cookie ? _self.cookie : cookie // ignore: cast_nullable_to_non_nullable
as String,preferResolvedExtension: null == preferResolvedExtension ? _self.preferResolvedExtension : preferResolvedExtension // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
