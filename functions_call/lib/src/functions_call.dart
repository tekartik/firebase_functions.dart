import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';

import 'functions_call_service.dart';

/// Options controlling how a [FirebaseFunctionsCallable] request is made,
/// such as [timeout] and [limitedUseAppCheckToken].
///
/// An instance is optionally passed to [FirebaseFunctionsCall.callable] or
/// [FirebaseFunctionsCall.callableFromUri] to customize the resulting
/// [FirebaseFunctionsCallable].
class FirebaseFunctionsCallableOptions {
  /// Constructs a new [FirebaseFunctionsCallableOptions] instance with the
  /// given [timeout] and [limitedUseAppCheckToken].
  ///
  /// [timeout] defaults to 60 seconds. [limitedUseAppCheckToken] defaults to
  /// `false`.
  FirebaseFunctionsCallableOptions({
    this.timeout = const Duration(seconds: 60),
    this.limitedUseAppCheckToken = false,
  });

  /// The maximum amount of time to wait for the Callable HTTPS trigger to
  /// respond before the call fails with a timeout error.
  ///
  /// Defaults to 60 seconds when not overridden in the constructor.
  Duration timeout;

  /// Whether to use a limited-use App Check token when invoking the
  /// associated function, instead of the standard cached App Check token.
  ///
  /// Limited-use tokens are single-use and intended for replay-protection
  /// sensitive calls (e.g. a purchase). Defaults to `false`.
  bool limitedUseAppCheckToken;

  @override
  String toString() =>
      'FirebaseFunctionsCallableOptions(timeout: $timeout${limitedUseAppCheckToken ? ', limitedUseAppCheckToken: $limitedUseAppCheckToken' : ''})';
}

/// Entry point for calling Firebase Cloud Functions callable (HTTPS
/// callable) triggers from a given [FirebaseApp].
///
/// One instance exists per [FirebaseApp] and is retrieved either through
/// [instance] (for the default app) or through the app-specific product
/// lookup provided by `tekartik_firebase`. Use [callable] or
/// [callableFromUri] to obtain a [FirebaseFunctionsCallable] for a specific
/// function.
abstract class FirebaseFunctionsCall
    implements FirebaseAppProduct<FirebaseFunctionsCall> {
  /// Returns a reference to the Callable HTTPS trigger with the given
  /// [name].
  ///
  /// [name] should be the name of the Callable function as deployed in
  /// Firebase. [options] optionally customizes the timeout and App Check
  /// behavior for calls made through the returned
  /// [FirebaseFunctionsCallable]; when omitted, implementation-specific
  /// defaults (matching [FirebaseFunctionsCallableOptions]'s defaults) are
  /// used.
  FirebaseFunctionsCallable callable(
    String name, {
    FirebaseFunctionsCallableOptions? options,
  });

  /// Returns a reference to the Callable HTTPS trigger at the given [uri].
  ///
  /// [uri] should be the URL of a 2nd gen Callable function in Firebase.
  /// [options] optionally customizes the timeout and App Check behavior for
  /// calls made through the returned [FirebaseFunctionsCallable]; when
  /// omitted, implementation-specific defaults (matching
  /// [FirebaseFunctionsCallableOptions]'s defaults) are used.
  FirebaseFunctionsCallable callableFromUri(
    Uri uri, {
    FirebaseFunctionsCallableOptions? options,
  });

  /// The [FirebaseFunctionsCall] instance registered on the default
  /// [FirebaseApp].
  ///
  /// Throws if no [FirebaseFunctionsCall] product has been registered on
  /// the default [FirebaseApp] (for example because the functions-call
  /// plugin for the current platform was not initialized).
  static FirebaseFunctionsCall get instance =>
      (FirebaseApp.instance as FirebaseAppMixin)
          .getProduct<FirebaseFunctionsCall>()!;

  /// The [FirebaseFunctionsCallService] used to create instances of this
  /// [FirebaseFunctionsCall].
  FirebaseFunctionsCallService get service;
}

/// A reference to a particular Callable HTTPS trigger in Cloud Functions.
///
/// Obtained through [FirebaseFunctionsCall.callable] or
/// [FirebaseFunctionsCall.callableFromUri].
abstract class FirebaseFunctionsCallable {
  /// Executes this Callable HTTPS trigger asynchronously with the given
  /// [parameters].
  ///
  /// [parameters] can be `null`, or any of the following types (nested
  /// arbitrarily):
  ///
  /// * `String`
  /// * `num`
  /// * [List], where the contained objects are also one of these types.
  /// * [Map], where the values are also one of these types.
  ///
  /// The request to the Cloud Functions backend made by this method
  /// automatically includes a Firebase Instance ID token to identify the app
  /// instance. If a user is logged in with Firebase Auth, an auth ID token for
  /// the user is also automatically included.
  ///
  /// Returns a [Future] that completes with the
  /// [FirebaseFunctionsCallableResult] once the function has finished
  /// executing and returned a response. The [Future] completes with an
  /// error if the request fails (network error, timeout as configured by
  /// [FirebaseFunctionsCallableOptions.timeout], or an error thrown by the
  /// remote function).
  Future<FirebaseFunctionsCallableResult<T>> call<T>([Object? parameters]);

  /// The name of the Callable HTTPS trigger this instance refers to, as
  /// passed to [FirebaseFunctionsCall.callable], or a value derived from
  /// its Uri when created through [FirebaseFunctionsCall.callableFromUri].
  String get name;
}

/// The result of invoking a [FirebaseFunctionsCallable] through
/// [FirebaseFunctionsCallable.call].
abstract class FirebaseFunctionsCallableResult<T> {
  /// The data that was returned from the Callable HTTPS trigger.
  T get data;

  /// Creates a new [FirebaseFunctionsCallableResult] wrapping the given
  /// [data].
  ///
  /// This is mainly useful for tests and mock implementations that need to
  /// produce a result without going through an actual function call.
  factory FirebaseFunctionsCallableResult(T data) =>
      _FirebaseFunctionsCallableResult<T>(data);
}

class _FirebaseFunctionsCallableResult<T>
    implements FirebaseFunctionsCallableResult<T> {
  @override
  final T data;

  _FirebaseFunctionsCallableResult(this.data);

  @override
  String toString() => 'CallableResult<$T>($data)';
}

/// Helper accessors for reading [FirebaseFunctionsCallableResult.data] as
/// JSON, for results whose `data` is a `String`, a `Map`, a `List`, or a
/// UTF-8 encoded byte list representing JSON.
extension FirebaseFunctionsCallableResultExt
    on FirebaseFunctionsCallableResult {
  /// The result [FirebaseFunctionsCallableResult.data] decoded as a JSON
  /// map.
  ///
  /// Throws if [dataAsMapOrNull] is `null`, i.e. if [data] cannot be
  /// decoded to a JSON map. Use [dataAsMapOrNull] instead when the data
  /// might legitimately not be a map.
  Map<String, Object?>? get dataAsMap => dataAsMapOrNull!;

  /// The result [FirebaseFunctionsCallableResult.data] decoded as a JSON
  /// map, or `null` if [data] is `null` or cannot be decoded to a JSON
  /// map.
  Map<String, Object?>? get dataAsMapOrNull => requestBodyAsJsonObject(data);

  /// The result [FirebaseFunctionsCallableResult.data] converted to a
  /// `String`.
  ///
  /// [data] is returned as-is if it is already a `String`; a `Map` or
  /// `List` is JSON-encoded; a byte list is UTF-8 decoded.
  String get dataAsText => requestBodyAsText(data);
}

/// Default mixin for [FirebaseFunctionsCallableResult] implementations.
///
/// Every member throws [UnimplementedError] until overridden. See
/// `functions_call_mixin.dart` for the rationale behind this pattern.
mixin FirebaseFunctionsCallableResultDefaultMixin<T>
    implements FirebaseFunctionsCallableResult<T> {
  /// Throws [UnimplementedError] unless overridden by the mixing class.
  @override
  T get data =>
      throw UnimplementedError('FirebaseFunctionsCallableResult.data');
}

/// Default mixin for [FirebaseFunctionsCall] implementations.
///
/// Every member throws [UnimplementedError] until overridden. See
/// `functions_call_mixin.dart` for the rationale behind this pattern.
mixin FirebaseFunctionsCallDefaultMixin implements FirebaseFunctionsCall {
  /// Throws [UnimplementedError] unless overridden by the mixing class.
  @override
  FirebaseFunctionsCallable callable(
    String name, {
    FirebaseFunctionsCallableOptions? options,
  }) {
    throw UnimplementedError('FirebaseFunctionsCall.callable ($runtimeType)');
  }

  /// Throws [UnimplementedError] unless overridden by the mixing class.
  @override
  FirebaseFunctionsCallable callableFromUri(
    Uri uri, {
    FirebaseFunctionsCallableOptions? options,
  }) {
    throw UnimplementedError(
      'FirebaseFunctionsCall.callableFromUri ($runtimeType)',
    );
  }
}

/// Default mixin for [FirebaseFunctionsCallable] implementations.
///
/// Every member throws [UnimplementedError] until overridden. See
/// `functions_call_mixin.dart` for the rationale behind this pattern.
mixin FirebaseFunctionsCallableDefaultMixin
    implements FirebaseFunctionsCallable {
  /// Throws [UnimplementedError] unless overridden by the mixing class.
  @override
  Future<FirebaseFunctionsCallableResult<T>> call<T>([Object? parameters]) {
    throw UnimplementedError('FirebaseFunctionsCallable.call ($runtimeType)');
  }

  /// Throws [UnimplementedError] unless overridden by the mixing class.
  @override
  String get name {
    throw UnimplementedError('FirebaseFunctionsCallable.name');
  }

  /// Returns `FirebaseFunctionsCallable(<name>)`, or falls back to
  /// [Object.toString] if reading [name] throws (i.e. when the mixing
  /// class has not overridden [name]).
  @override
  String toString() {
    try {
      return 'FirebaseFunctionsCallable($name)';
    } catch (_) {
      return super.toString();
    }
  }
}

// ignore: unused_element
class _FirebaseFunctionsCallMock
    with
        FirebaseFunctionsCallDefaultMixin,
        FirebaseAppProductMixin<FirebaseFunctionsCall>
    implements FirebaseFunctionsCall {
  @override
  FirebaseFunctionsCallService get service => throw UnimplementedError();

  @override
  FirebaseApp get app => throw UnimplementedError();
}

// ignore: unused_element
class _FirebaseFunctionsCallableMock
    with FirebaseFunctionsCallableDefaultMixin
    implements FirebaseFunctionsCallable {}

// ignore: unused_element
class _FirebaseFunctionsCallableResultsMock<T>
    with FirebaseFunctionsCallableResultDefaultMixin<T>
    implements FirebaseFunctionsCallableResult<T> {}
