// import 'package:tekartik_http/http_server.dart';

import 'firebase_functions.dart';

export 'package:tekartik_firebase_firestore/firestore.dart'
    show DocumentSnapshot, Timestamp;

/// Registers HTTPS-triggered functions: raw request handlers and JSON
/// callable functions.
abstract class HttpsFunctions {
  /// Registers [handler] as a raw HTTPS request function. This is the
  /// preferred way to register HTTPS request handlers.
  ///
  /// [httpsOptions] configures cors, region, memory and other deployment
  /// options; if omitted, the current [FirebaseFunctions.globalOptions]
  /// (or the platform defaults) apply.
  ///
  /// Returns the resulting [HttpsFunction].
  HttpsFunction onRequest(RequestHandler handler, {HttpsOptions? httpsOptions});

  /// Registers [handler] as a raw HTTPS request function with explicit
  /// [httpsOptions] (compatibility variant of [onRequest] taking the
  /// options as a required positional parameter).
  ///
  /// Returns the resulting [HttpsFunction].
  HttpsFunction onRequestV2(HttpsOptions httpsOptions, RequestHandler handler);

  /// Registers [handler] as a callable function, invoked with a decoded
  /// [CallRequest] and returning the JSON-encodable response.
  ///
  /// [callableOptions] configures App Check enforcement, cors, region and
  /// other deployment options; if omitted, the current
  /// [FirebaseFunctions.globalOptions] (or the platform defaults) apply.
  ///
  /// Returns the resulting [HttpsCallableFunction].
  HttpsCallableFunction onCall(
    CallHandler handler, {
    HttpsCallableOptions? callableOptions,
  });
}

/// Default mixin for [HttpsFunctions] implementations, no-op by default so
/// that partial implementations never break compilation; every member
/// throws an [UnimplementedError] unless overridden.
mixin HttpsFunctionsDefaultMixin implements HttpsFunctions {
  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  HttpsCallableFunction onCall(
    CallHandler handler, {
    HttpsCallableOptions? callableOptions,
  }) => throw UnimplementedError('onCall');

  /// Default implementation, delegates to [onRequest] with [httpsOptions].
  @override
  HttpsFunction onRequestV2(
    HttpsOptions httpsOptions,
    RequestHandler handler,
  ) => onRequest(handler, httpsOptions: httpsOptions);

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  HttpsFunction onRequest(
    RequestHandler handler, {
    HttpsOptions? httpsOptions,
  }) {
    throw UnimplementedError('onRequest');
  }
}

/// Https function.
abstract class HttpsFunction implements FirebaseFunction {}

/// Callable function.
abstract class HttpsCallableFunction implements FirebaseFunction {}

/// Options for a callable function, passed to [HttpsFunctions.onCall].
class HttpsCallableOptions extends HttpsOptions {
  /// Determines whether the Firebase App Check token is consumed on
  /// request. `null` is treated as `false` (the token is not consumed).
  final bool? consumeAppCheckToken;

  /// Determines whether Firebase App Check is enforced. When `true`,
  /// requests with invalid tokens automatically respond with a 401
  /// (Unauthorized) error. When `false` (or `null`), requests with invalid
  /// tokens leave the app-check event field undefined instead of failing.
  final bool? enforceAppCheck;

  /// Creates the options for a callable function. All parameters are
  /// optional; a `null`/omitted value leaves the corresponding setting at
  /// its platform default (see [HttpsOptions] and [GlobalOptions] for the
  /// inherited parameters).
  HttpsCallableOptions({
    this.consumeAppCheckToken,
    this.enforceAppCheck,
    super.cors,
    super.concurrency,
    super.memory,
    super.region,
    super.regions,
    super.timeoutSeconds,
    super.maxInstances,
  });
}

/// Options for a raw HTTPS request function, passed to
/// [HttpsFunctions.onRequest] and [HttpsFunctions.onRequestV2].
class HttpsOptions extends GlobalOptions {
  /// Set to `true` to allow cross-origin requests (CORS). `null`/omitted
  /// leaves CORS handling at the platform default (disabled).
  final bool? cors;

  /// Creates HTTPS options. All parameters are optional; a `null`/omitted
  /// value leaves the corresponding setting at its platform default (see
  /// [GlobalOptions] for the inherited parameters).
  HttpsOptions({
    this.cors,
    super.concurrency,
    super.memory,
    super.region,
    super.regions,
    super.timeoutSeconds,
    super.maxInstances,
  });
}

/// Exception representing an error returned by an HTTPS callable function
/// to its client, carrying a [code], [message] and optional [details].
class HttpsError implements Exception {
  /// Creates an [HttpsError] with a [code] (see [HttpsErrorCode]), a
  /// [message] describing the error, and optional [details] to include in
  /// the response body.
  HttpsError(this.code, this.message, [this.details]);

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

  /// Returns a debug string representation of this error as a map
  /// containing [code], [message] and, when non-null, [details].
  @override
  String toString() =>
      {'code': code, 'message': message, 'details': ?details}.toString();
}

/// The set of Firebase Functions status codes usable as [HttpsError.code],
/// mirroring the gRPC status codes: "ok" | "cancelled" | "unknown" |
/// "invalid-argument" | "deadline-exceeded" | "not-found" |
/// "already-exists" | "permission-denied" | "resource-exhausted" |
/// "failed-precondition" | "aborted" | "out-of-range" | "unimplemented" |
/// "internal" | "unavailable" | "data-loss" | "unauthenticated".
abstract class HttpsErrorCode {
  /// The operation completed successfully.
  static const ok = 'ok';

  /// The operation was cancelled, typically by the caller.
  static const cancelled = 'cancelled';

  /// Unknown error or an error from a different error domain.
  static const unknown = 'unknown';

  /// The client specified an invalid argument.
  static const invalidArgument = 'invalid-argument';

  /// Deadline expired before the operation could complete.
  static const deadlineExceeded = 'deadline-exceeded';

  /// Some requested document/resource was not found.
  static const notFound = 'not-found';

  /// Some document/resource that was attempted to be created already
  /// exists.
  static const alreadyExists = 'already-exists';

  /// The caller does not have permission to execute the specified
  /// operation.
  static const permissionDenied = 'permission-denied';

  /// Some resource has been exhausted, such as a per-user quota.
  static const resourceExhausted = 'resource-exhausted';

  /// The operation was rejected because the system is not in a state
  /// required for the operation's execution.
  static const failedPrecondition = 'failed-precondition';

  /// The operation was aborted, typically due to a concurrency issue.
  static const aborted = 'aborted';

  /// The operation was attempted past the valid range.
  static const outOrRange = 'out-of-range';

  /// The operation is not implemented or not supported/enabled.
  static const unimplemented = 'unimplemented';

  /// Internal error, some invariant expected by the underlying system has
  /// been broken.
  static const internal = 'internal';

  /// The service is currently unavailable, typically a transient
  /// condition.
  static const unavailable = 'unavailable';

  /// Unrecoverable data loss or corruption.
  static const dataLoss = 'data-loss';

  /// The request does not have valid authentication credentials for the
  /// operation.
  static const unauthenticated = 'unauthenticated';
}
