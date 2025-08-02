import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';

import 'functions_call_service.dart';

/// Interface representing an HttpsCallable instance's options,
class FirebaseFunctionsCallableOptions {
  /// Constructs a new [HttpsCallableOptions] instance with given `timeout` & `limitedUseAppCheckToken`
  /// Defaults [timeout] to 60 seconds.
  /// Defaults [limitedUseAppCheckToken] to `false`
  FirebaseFunctionsCallableOptions({
    this.timeout = const Duration(seconds: 60),
    this.limitedUseAppCheckToken = false,
  });

  /// Returns the timeout for this instance
  Duration timeout;

  /// Sets whether or not to use limited-use App Check tokens when invoking the associated function.
  bool limitedUseAppCheckToken;

  @override
  String toString() =>
      'FirebaseFunctionsCallableOptions(timeout: $timeout${limitedUseAppCheckToken ? ', limitedUseAppCheckToken: $limitedUseAppCheckToken' : ''})';
}

/// Firebase functions call
abstract class FirebaseFunctionsCall
    implements FirebaseAppProduct<FirebaseFunctionsCall> {
  /// A reference to the Callable HTTPS trigger with the given name.
  ///
  /// Should be the name of the Callable function in Firebase
  FirebaseFunctionsCallable callable(
    String name, {
    FirebaseFunctionsCallableOptions? options,
  });

  /// Default Firebase functions call instance.
  static FirebaseFunctionsCall get instance =>
      (FirebaseApp.instance as FirebaseAppMixin)
          .getProduct<FirebaseFunctionsCall>()!;

  /// Service access
  FirebaseFunctionsCallService get service;
}

/// A reference to a particular Callable HTTPS trigger in Cloud Functions.
abstract class FirebaseFunctionsCallable {
  /// Executes this Callable HTTPS trigger asynchronously.
  ///
  /// The data passed into the trigger can be any of the following types:
  ///
  /// `null`
  /// `String`
  /// `num`
  /// [List], where the contained objects are also one of these types.
  /// [Map], where the values are also one of these types.
  ///
  /// The request to the Cloud Functions backend made by this method
  /// automatically includes a Firebase Instance ID token to identify the app
  /// instance. If a user is logged in with Firebase Auth, an auth ID token for
  /// the user is also automatically included.
  Future<FirebaseFunctionsCallableResult<T>> call<T>([Object? parameters]);
}

/// Firebase functions callable result.
abstract class FirebaseFunctionsCallableResult<T> {
  /// The data that was returned from the Callable HTTPS trigger.
  T get data;
}

/// Firebase functions callable result helper extension
extension FirebaseFunctionsCallableResultExt
    on FirebaseFunctionsCallableResult {
  /// Get the body as a map
  Map<String, Object?>? get dataAsMap => dataAsMapOrNull!;

  /// Get the body as a map
  Map<String, Object?>? get dataAsMapOrNull => requestBodyAsJsonObject(data);

  /// Get the body as a text
  String get dataAsText => requestBodyAsText(data);
}

/// Firebase functions callable result default mixin
mixin FirebaseFunctionsCallableResultDefaultMixin<T>
    implements FirebaseFunctionsCallableResult<T> {
  @override
  T get data =>
      throw UnimplementedError('FirebaseFunctionsCallableResult.data');
}

/// Firebase functions call default mixin
mixin FirebaseFunctionsCallDefaultMixin implements FirebaseFunctionsCall {
  @override
  FirebaseFunctionsCallable callable(
    String name, {
    FirebaseFunctionsCallableOptions? options,
  }) {
    throw UnimplementedError('FirebaseFunctionsCall.callable');
  }
}

/// Firebase functions callable default mixin
mixin FirebaseFunctionsCallableDefaultMixin
    implements FirebaseFunctionsCallable {
  @override
  Future<FirebaseFunctionsCallableResult<T>> call<T>([Object? parameters]) {
    throw UnimplementedError('FirebaseFunctionsCallable.call');
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
class _FirebaseFunctionsCallableResultsMock
    with FirebaseFunctionsCallableResultDefaultMixin
    implements FirebaseFunctionsCallableResult {}
