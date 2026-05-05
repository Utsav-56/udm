// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'manager_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ManagerPreferences {

 int get maxConcurrentDownloads; int get threadCount; String get userAgent; Map<String, String> get customHeaders; String get cookie; bool get retryOnFailure; int get maxRetries; int get timeout; int get maxConnectionsPerHost; int get idleTimeout; bool get followRedirects; bool get ignoreBadCertificate; String get savePath; String get tempPath; bool get deleteFileOnCancel; bool get preferServerFileExtension; int get maxSpeed; int get minSpeed;
/// Create a copy of ManagerPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ManagerPreferencesCopyWith<ManagerPreferences> get copyWith => _$ManagerPreferencesCopyWithImpl<ManagerPreferences>(this as ManagerPreferences, _$identity);

  /// Serializes this ManagerPreferences to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ManagerPreferences&&(identical(other.maxConcurrentDownloads, maxConcurrentDownloads) || other.maxConcurrentDownloads == maxConcurrentDownloads)&&(identical(other.threadCount, threadCount) || other.threadCount == threadCount)&&(identical(other.userAgent, userAgent) || other.userAgent == userAgent)&&const DeepCollectionEquality().equals(other.customHeaders, customHeaders)&&(identical(other.cookie, cookie) || other.cookie == cookie)&&(identical(other.retryOnFailure, retryOnFailure) || other.retryOnFailure == retryOnFailure)&&(identical(other.maxRetries, maxRetries) || other.maxRetries == maxRetries)&&(identical(other.timeout, timeout) || other.timeout == timeout)&&(identical(other.maxConnectionsPerHost, maxConnectionsPerHost) || other.maxConnectionsPerHost == maxConnectionsPerHost)&&(identical(other.idleTimeout, idleTimeout) || other.idleTimeout == idleTimeout)&&(identical(other.followRedirects, followRedirects) || other.followRedirects == followRedirects)&&(identical(other.ignoreBadCertificate, ignoreBadCertificate) || other.ignoreBadCertificate == ignoreBadCertificate)&&(identical(other.savePath, savePath) || other.savePath == savePath)&&(identical(other.tempPath, tempPath) || other.tempPath == tempPath)&&(identical(other.deleteFileOnCancel, deleteFileOnCancel) || other.deleteFileOnCancel == deleteFileOnCancel)&&(identical(other.preferServerFileExtension, preferServerFileExtension) || other.preferServerFileExtension == preferServerFileExtension)&&(identical(other.maxSpeed, maxSpeed) || other.maxSpeed == maxSpeed)&&(identical(other.minSpeed, minSpeed) || other.minSpeed == minSpeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxConcurrentDownloads,threadCount,userAgent,const DeepCollectionEquality().hash(customHeaders),cookie,retryOnFailure,maxRetries,timeout,maxConnectionsPerHost,idleTimeout,followRedirects,ignoreBadCertificate,savePath,tempPath,deleteFileOnCancel,preferServerFileExtension,maxSpeed,minSpeed);

@override
String toString() {
  return 'ManagerPreferences(maxConcurrentDownloads: $maxConcurrentDownloads, threadCount: $threadCount, userAgent: $userAgent, customHeaders: $customHeaders, cookie: $cookie, retryOnFailure: $retryOnFailure, maxRetries: $maxRetries, timeout: $timeout, maxConnectionsPerHost: $maxConnectionsPerHost, idleTimeout: $idleTimeout, followRedirects: $followRedirects, ignoreBadCertificate: $ignoreBadCertificate, savePath: $savePath, tempPath: $tempPath, deleteFileOnCancel: $deleteFileOnCancel, preferServerFileExtension: $preferServerFileExtension, maxSpeed: $maxSpeed, minSpeed: $minSpeed)';
}


}

/// @nodoc
abstract mixin class $ManagerPreferencesCopyWith<$Res>  {
  factory $ManagerPreferencesCopyWith(ManagerPreferences value, $Res Function(ManagerPreferences) _then) = _$ManagerPreferencesCopyWithImpl;
@useResult
$Res call({
 int maxConcurrentDownloads, int threadCount, String userAgent, Map<String, String> customHeaders, String cookie, bool retryOnFailure, int maxRetries, int timeout, int maxConnectionsPerHost, int idleTimeout, bool followRedirects, bool ignoreBadCertificate, String savePath, String tempPath, bool deleteFileOnCancel, bool preferServerFileExtension, int maxSpeed, int minSpeed
});




}
/// @nodoc
class _$ManagerPreferencesCopyWithImpl<$Res>
    implements $ManagerPreferencesCopyWith<$Res> {
  _$ManagerPreferencesCopyWithImpl(this._self, this._then);

  final ManagerPreferences _self;
  final $Res Function(ManagerPreferences) _then;

/// Create a copy of ManagerPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxConcurrentDownloads = null,Object? threadCount = null,Object? userAgent = null,Object? customHeaders = null,Object? cookie = null,Object? retryOnFailure = null,Object? maxRetries = null,Object? timeout = null,Object? maxConnectionsPerHost = null,Object? idleTimeout = null,Object? followRedirects = null,Object? ignoreBadCertificate = null,Object? savePath = null,Object? tempPath = null,Object? deleteFileOnCancel = null,Object? preferServerFileExtension = null,Object? maxSpeed = null,Object? minSpeed = null,}) {
  return _then(_self.copyWith(
maxConcurrentDownloads: null == maxConcurrentDownloads ? _self.maxConcurrentDownloads : maxConcurrentDownloads // ignore: cast_nullable_to_non_nullable
as int,threadCount: null == threadCount ? _self.threadCount : threadCount // ignore: cast_nullable_to_non_nullable
as int,userAgent: null == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String,customHeaders: null == customHeaders ? _self.customHeaders : customHeaders // ignore: cast_nullable_to_non_nullable
as Map<String, String>,cookie: null == cookie ? _self.cookie : cookie // ignore: cast_nullable_to_non_nullable
as String,retryOnFailure: null == retryOnFailure ? _self.retryOnFailure : retryOnFailure // ignore: cast_nullable_to_non_nullable
as bool,maxRetries: null == maxRetries ? _self.maxRetries : maxRetries // ignore: cast_nullable_to_non_nullable
as int,timeout: null == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as int,maxConnectionsPerHost: null == maxConnectionsPerHost ? _self.maxConnectionsPerHost : maxConnectionsPerHost // ignore: cast_nullable_to_non_nullable
as int,idleTimeout: null == idleTimeout ? _self.idleTimeout : idleTimeout // ignore: cast_nullable_to_non_nullable
as int,followRedirects: null == followRedirects ? _self.followRedirects : followRedirects // ignore: cast_nullable_to_non_nullable
as bool,ignoreBadCertificate: null == ignoreBadCertificate ? _self.ignoreBadCertificate : ignoreBadCertificate // ignore: cast_nullable_to_non_nullable
as bool,savePath: null == savePath ? _self.savePath : savePath // ignore: cast_nullable_to_non_nullable
as String,tempPath: null == tempPath ? _self.tempPath : tempPath // ignore: cast_nullable_to_non_nullable
as String,deleteFileOnCancel: null == deleteFileOnCancel ? _self.deleteFileOnCancel : deleteFileOnCancel // ignore: cast_nullable_to_non_nullable
as bool,preferServerFileExtension: null == preferServerFileExtension ? _self.preferServerFileExtension : preferServerFileExtension // ignore: cast_nullable_to_non_nullable
as bool,maxSpeed: null == maxSpeed ? _self.maxSpeed : maxSpeed // ignore: cast_nullable_to_non_nullable
as int,minSpeed: null == minSpeed ? _self.minSpeed : minSpeed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ManagerPreferences].
extension ManagerPreferencesPatterns on ManagerPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ManagerPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ManagerPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ManagerPreferences value)  $default,){
final _that = this;
switch (_that) {
case _ManagerPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ManagerPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _ManagerPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int maxConcurrentDownloads,  int threadCount,  String userAgent,  Map<String, String> customHeaders,  String cookie,  bool retryOnFailure,  int maxRetries,  int timeout,  int maxConnectionsPerHost,  int idleTimeout,  bool followRedirects,  bool ignoreBadCertificate,  String savePath,  String tempPath,  bool deleteFileOnCancel,  bool preferServerFileExtension,  int maxSpeed,  int minSpeed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ManagerPreferences() when $default != null:
return $default(_that.maxConcurrentDownloads,_that.threadCount,_that.userAgent,_that.customHeaders,_that.cookie,_that.retryOnFailure,_that.maxRetries,_that.timeout,_that.maxConnectionsPerHost,_that.idleTimeout,_that.followRedirects,_that.ignoreBadCertificate,_that.savePath,_that.tempPath,_that.deleteFileOnCancel,_that.preferServerFileExtension,_that.maxSpeed,_that.minSpeed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int maxConcurrentDownloads,  int threadCount,  String userAgent,  Map<String, String> customHeaders,  String cookie,  bool retryOnFailure,  int maxRetries,  int timeout,  int maxConnectionsPerHost,  int idleTimeout,  bool followRedirects,  bool ignoreBadCertificate,  String savePath,  String tempPath,  bool deleteFileOnCancel,  bool preferServerFileExtension,  int maxSpeed,  int minSpeed)  $default,) {final _that = this;
switch (_that) {
case _ManagerPreferences():
return $default(_that.maxConcurrentDownloads,_that.threadCount,_that.userAgent,_that.customHeaders,_that.cookie,_that.retryOnFailure,_that.maxRetries,_that.timeout,_that.maxConnectionsPerHost,_that.idleTimeout,_that.followRedirects,_that.ignoreBadCertificate,_that.savePath,_that.tempPath,_that.deleteFileOnCancel,_that.preferServerFileExtension,_that.maxSpeed,_that.minSpeed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int maxConcurrentDownloads,  int threadCount,  String userAgent,  Map<String, String> customHeaders,  String cookie,  bool retryOnFailure,  int maxRetries,  int timeout,  int maxConnectionsPerHost,  int idleTimeout,  bool followRedirects,  bool ignoreBadCertificate,  String savePath,  String tempPath,  bool deleteFileOnCancel,  bool preferServerFileExtension,  int maxSpeed,  int minSpeed)?  $default,) {final _that = this;
switch (_that) {
case _ManagerPreferences() when $default != null:
return $default(_that.maxConcurrentDownloads,_that.threadCount,_that.userAgent,_that.customHeaders,_that.cookie,_that.retryOnFailure,_that.maxRetries,_that.timeout,_that.maxConnectionsPerHost,_that.idleTimeout,_that.followRedirects,_that.ignoreBadCertificate,_that.savePath,_that.tempPath,_that.deleteFileOnCancel,_that.preferServerFileExtension,_that.maxSpeed,_that.minSpeed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ManagerPreferences extends ManagerPreferences {
  const _ManagerPreferences({this.maxConcurrentDownloads = 4, this.threadCount = 8, this.userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3", final  Map<String, String> customHeaders = const {}, this.cookie = "", this.retryOnFailure = true, this.maxRetries = 3, this.timeout = 10, this.maxConnectionsPerHost = 4, this.idleTimeout = 5, this.followRedirects = true, this.ignoreBadCertificate = false, this.savePath = "", this.tempPath = "", this.deleteFileOnCancel = false, this.preferServerFileExtension = true, this.maxSpeed = 0, this.minSpeed = 0}): _customHeaders = customHeaders,super._();
  factory _ManagerPreferences.fromJson(Map<String, dynamic> json) => _$ManagerPreferencesFromJson(json);

@override@JsonKey() final  int maxConcurrentDownloads;
@override@JsonKey() final  int threadCount;
@override@JsonKey() final  String userAgent;
 final  Map<String, String> _customHeaders;
@override@JsonKey() Map<String, String> get customHeaders {
  if (_customHeaders is EqualUnmodifiableMapView) return _customHeaders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_customHeaders);
}

@override@JsonKey() final  String cookie;
@override@JsonKey() final  bool retryOnFailure;
@override@JsonKey() final  int maxRetries;
@override@JsonKey() final  int timeout;
@override@JsonKey() final  int maxConnectionsPerHost;
@override@JsonKey() final  int idleTimeout;
@override@JsonKey() final  bool followRedirects;
@override@JsonKey() final  bool ignoreBadCertificate;
@override@JsonKey() final  String savePath;
@override@JsonKey() final  String tempPath;
@override@JsonKey() final  bool deleteFileOnCancel;
@override@JsonKey() final  bool preferServerFileExtension;
@override@JsonKey() final  int maxSpeed;
@override@JsonKey() final  int minSpeed;

/// Create a copy of ManagerPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ManagerPreferencesCopyWith<_ManagerPreferences> get copyWith => __$ManagerPreferencesCopyWithImpl<_ManagerPreferences>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ManagerPreferencesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ManagerPreferences&&(identical(other.maxConcurrentDownloads, maxConcurrentDownloads) || other.maxConcurrentDownloads == maxConcurrentDownloads)&&(identical(other.threadCount, threadCount) || other.threadCount == threadCount)&&(identical(other.userAgent, userAgent) || other.userAgent == userAgent)&&const DeepCollectionEquality().equals(other._customHeaders, _customHeaders)&&(identical(other.cookie, cookie) || other.cookie == cookie)&&(identical(other.retryOnFailure, retryOnFailure) || other.retryOnFailure == retryOnFailure)&&(identical(other.maxRetries, maxRetries) || other.maxRetries == maxRetries)&&(identical(other.timeout, timeout) || other.timeout == timeout)&&(identical(other.maxConnectionsPerHost, maxConnectionsPerHost) || other.maxConnectionsPerHost == maxConnectionsPerHost)&&(identical(other.idleTimeout, idleTimeout) || other.idleTimeout == idleTimeout)&&(identical(other.followRedirects, followRedirects) || other.followRedirects == followRedirects)&&(identical(other.ignoreBadCertificate, ignoreBadCertificate) || other.ignoreBadCertificate == ignoreBadCertificate)&&(identical(other.savePath, savePath) || other.savePath == savePath)&&(identical(other.tempPath, tempPath) || other.tempPath == tempPath)&&(identical(other.deleteFileOnCancel, deleteFileOnCancel) || other.deleteFileOnCancel == deleteFileOnCancel)&&(identical(other.preferServerFileExtension, preferServerFileExtension) || other.preferServerFileExtension == preferServerFileExtension)&&(identical(other.maxSpeed, maxSpeed) || other.maxSpeed == maxSpeed)&&(identical(other.minSpeed, minSpeed) || other.minSpeed == minSpeed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxConcurrentDownloads,threadCount,userAgent,const DeepCollectionEquality().hash(_customHeaders),cookie,retryOnFailure,maxRetries,timeout,maxConnectionsPerHost,idleTimeout,followRedirects,ignoreBadCertificate,savePath,tempPath,deleteFileOnCancel,preferServerFileExtension,maxSpeed,minSpeed);

@override
String toString() {
  return 'ManagerPreferences(maxConcurrentDownloads: $maxConcurrentDownloads, threadCount: $threadCount, userAgent: $userAgent, customHeaders: $customHeaders, cookie: $cookie, retryOnFailure: $retryOnFailure, maxRetries: $maxRetries, timeout: $timeout, maxConnectionsPerHost: $maxConnectionsPerHost, idleTimeout: $idleTimeout, followRedirects: $followRedirects, ignoreBadCertificate: $ignoreBadCertificate, savePath: $savePath, tempPath: $tempPath, deleteFileOnCancel: $deleteFileOnCancel, preferServerFileExtension: $preferServerFileExtension, maxSpeed: $maxSpeed, minSpeed: $minSpeed)';
}


}

/// @nodoc
abstract mixin class _$ManagerPreferencesCopyWith<$Res> implements $ManagerPreferencesCopyWith<$Res> {
  factory _$ManagerPreferencesCopyWith(_ManagerPreferences value, $Res Function(_ManagerPreferences) _then) = __$ManagerPreferencesCopyWithImpl;
@override @useResult
$Res call({
 int maxConcurrentDownloads, int threadCount, String userAgent, Map<String, String> customHeaders, String cookie, bool retryOnFailure, int maxRetries, int timeout, int maxConnectionsPerHost, int idleTimeout, bool followRedirects, bool ignoreBadCertificate, String savePath, String tempPath, bool deleteFileOnCancel, bool preferServerFileExtension, int maxSpeed, int minSpeed
});




}
/// @nodoc
class __$ManagerPreferencesCopyWithImpl<$Res>
    implements _$ManagerPreferencesCopyWith<$Res> {
  __$ManagerPreferencesCopyWithImpl(this._self, this._then);

  final _ManagerPreferences _self;
  final $Res Function(_ManagerPreferences) _then;

/// Create a copy of ManagerPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxConcurrentDownloads = null,Object? threadCount = null,Object? userAgent = null,Object? customHeaders = null,Object? cookie = null,Object? retryOnFailure = null,Object? maxRetries = null,Object? timeout = null,Object? maxConnectionsPerHost = null,Object? idleTimeout = null,Object? followRedirects = null,Object? ignoreBadCertificate = null,Object? savePath = null,Object? tempPath = null,Object? deleteFileOnCancel = null,Object? preferServerFileExtension = null,Object? maxSpeed = null,Object? minSpeed = null,}) {
  return _then(_ManagerPreferences(
maxConcurrentDownloads: null == maxConcurrentDownloads ? _self.maxConcurrentDownloads : maxConcurrentDownloads // ignore: cast_nullable_to_non_nullable
as int,threadCount: null == threadCount ? _self.threadCount : threadCount // ignore: cast_nullable_to_non_nullable
as int,userAgent: null == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String,customHeaders: null == customHeaders ? _self._customHeaders : customHeaders // ignore: cast_nullable_to_non_nullable
as Map<String, String>,cookie: null == cookie ? _self.cookie : cookie // ignore: cast_nullable_to_non_nullable
as String,retryOnFailure: null == retryOnFailure ? _self.retryOnFailure : retryOnFailure // ignore: cast_nullable_to_non_nullable
as bool,maxRetries: null == maxRetries ? _self.maxRetries : maxRetries // ignore: cast_nullable_to_non_nullable
as int,timeout: null == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as int,maxConnectionsPerHost: null == maxConnectionsPerHost ? _self.maxConnectionsPerHost : maxConnectionsPerHost // ignore: cast_nullable_to_non_nullable
as int,idleTimeout: null == idleTimeout ? _self.idleTimeout : idleTimeout // ignore: cast_nullable_to_non_nullable
as int,followRedirects: null == followRedirects ? _self.followRedirects : followRedirects // ignore: cast_nullable_to_non_nullable
as bool,ignoreBadCertificate: null == ignoreBadCertificate ? _self.ignoreBadCertificate : ignoreBadCertificate // ignore: cast_nullable_to_non_nullable
as bool,savePath: null == savePath ? _self.savePath : savePath // ignore: cast_nullable_to_non_nullable
as String,tempPath: null == tempPath ? _self.tempPath : tempPath // ignore: cast_nullable_to_non_nullable
as String,deleteFileOnCancel: null == deleteFileOnCancel ? _self.deleteFileOnCancel : deleteFileOnCancel // ignore: cast_nullable_to_non_nullable
as bool,preferServerFileExtension: null == preferServerFileExtension ? _self.preferServerFileExtension : preferServerFileExtension // ignore: cast_nullable_to_non_nullable
as bool,maxSpeed: null == maxSpeed ? _self.maxSpeed : maxSpeed // ignore: cast_nullable_to_non_nullable
as int,minSpeed: null == minSpeed ? _self.minSpeed : minSpeed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
