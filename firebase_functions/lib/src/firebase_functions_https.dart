// import 'package:tekartik_http/http_server.dart';

import 'firebase_functions.dart';

export 'package:tekartik_firebase_firestore/firestore.dart'
    show DocumentSnapshot, Timestamp;

abstract class HttpsFunctions {
  /// HTTPS request - preferred
  HttpsFunction onRequest(RequestHandler handler, {HttpsOptions? httpsOptions});

  /// HTTPS request with options (compat)
  HttpsFunction onRequestV2(HttpsOptions httpsOptions, RequestHandler handler);

  /// call request
  HttpsCallableFunction onCall(CallHandler handler,
      {HttpsCallableOptions? callableOptions});
}

/// no-op by default to never break compilation
mixin HttpsFunctionsDefaultMixin implements HttpsFunctions {
  @override
  HttpsCallableFunction onCall(CallHandler handler,
          {HttpsCallableOptions? callableOptions}) =>
      throw UnimplementedError('onCall');

  @override
  HttpsFunction onRequestV2(
          HttpsOptions httpsOptions, RequestHandler handler) =>
      onRequest(handler, httpsOptions: httpsOptions);

  @override
  HttpsFunction onRequest(RequestHandler handler,
      {HttpsOptions? httpsOptions}) {
    throw UnimplementedError('onRequest');
  }
}

/// Https function.
abstract class HttpsFunction implements FirebaseFunction {}

/// Callable function.
abstract class HttpsCallableFunction implements FirebaseFunction {}

/// Callable options
class HttpsCallableOptions extends HttpsOptions {
  /// Determines whether Firebase App Check token is consumed on request. Defaults to false.
  final bool? consumeAppCheckToken;

  /// Determines whether Firebase AppCheck is enforced. When true, requests with invalid tokens autorespond with a 401 (Unauthorized) error. When false, requests with invalid tokens set event.app to undefiend.
  final bool? enforceAppCheck;
  HttpsCallableOptions(
      {this.consumeAppCheckToken,
      this.enforceAppCheck,
      super.cors,
      super.concurrency,
      super.memory,
      super.region,
      super.regions,
      super.timeoutSeconds});
}

/// Https options
class HttpsOptions extends GlobalOptions {
  /// Set to true to allow cors
  final bool? cors;

  HttpsOptions(
      {this.cors,
      super.concurrency,
      super.memory,
      super.region,
      super.regions,
      super.timeoutSeconds});
}

/// Error thrown
class HttpsError implements Exception {
  HttpsError(this.code, this.message, this.details);

  /// A status error code to include in the response.
  final String code;

  /// A message string to be included in the response body to the client.
  final String message;

  /// An object to include in the "details" field of the response body.
  ///
  /// As with the data returned from a callable HTTPS handler, this can be
  /// `null` or any JSON-encodable object (`String`, `int`, `List` or `Map`
  /// containing primitive types).
  final Object? details;

  @override
  String toString() => {
        'code': code,
        'message': message,
        if (details != null) 'details': details
      }.toString();
}

/// FunctionsErrorCode: "ok" | "cancelled" | "unknown" | "invalid-argument" | "deadline-exceeded" | "not-found" | "already-exists" | "permission-denied" | "resource-exhausted" | "failed-precondition" | "aborted" | "out-of-range" | "unimplemented" | "internal" | "unavailable" | "data-loss" | "unauthenticated"
abstract class HttpsErrorCode {
  static const ok = 'ok';
  static const cancelled = 'cancelled';
  static const unknown = 'unknown';
  static const invalidArgument = 'invalid-argument';
  static const deadlineExceeded = 'deadline-exceeded';
  static const notFound = 'not-found';
  static const alreadyExists = 'already-exists';
  static const permissionDenied = 'permission-denied';
  static const resourceExhausted = 'resource-exhausted';
  static const failedPrecondition = 'failed-precondition';
  static const aborted = 'aborted';
  static const outOrRange = 'out-of-range';
  static const unimplemented = 'unimplemented';
  static const internal = 'internal';
  static const unavailable = 'unavailable';
  static const dataLoss = 'data-loss';
  static const unauthenticated = 'unauthenticated';
}
