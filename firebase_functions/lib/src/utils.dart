import 'dart:convert';

import 'package:cv/cv_json.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_http/http.dart';

/// Convenience accessor to decode a [CallRequest] payload.
extension CallRequestFfExt on CallRequest {
  /// Returns the request payload as a `Map<String, Object?>`.
  ///
  /// If [CallRequest.data] is already a `Map`, it is cast directly;
  /// otherwise [CallRequest.text] is JSON-decoded and cast.
  ///
  /// Throws if the data is neither a `Map` nor JSON-decodable to a `Map`,
  /// or if [CallRequest.text] is `null`.
  Map<String, Object?> getRequestAsMap() {
    Map map;
    if (data is Map) {
      map = data as Map;
    } else {
      map = jsonDecode(text!) as Map;
    }
    return map.cast<String, Object?>();
  }
}

/// Convenience adapter to invoke a [CallHandler] from a raw
/// [ExpressHttpRequest] (as opposed to a real callable-function
/// invocation), mainly useful for HTTP-based testing.
extension ExpressHttpRequestFfExt on ExpressHttpRequest {
  /// Invokes [handler] with a [CallRequest] built from this request's body,
  /// then writes the result (or any thrown error) as a JSON response.
  ///
  /// On success, the handler's return value is written as the response
  /// body (as a JSON string, or as-is if it is already a `String`) with a
  /// `application/json` content type.
  ///
  /// On failure, an [HttpsError] (or any other exception, wrapped as an
  /// internal error) is written as a JSON `{'error': {...}}` body with a
  /// 500 status code.
  ///
  /// The returned [Future] completes once the response has been sent.
  Future<void> handleWithCallHandler(CallHandler handler) async {
    var result = await handler(CallRequestFromExpress(request: this));
    try {
      response.headers.set(httpHeaderContentType, httpContentTypeJson);
      var responseString = result is String ? result : jsonEncode(result);
      await response.send(responseString);
    } catch (e) {
      var errorCode = HttpsErrorCode.internal;
      var message = e.toString();
      Object? details;
      if (e is HttpsError) {
        errorCode = e.code;
        message = e.message;
        details = e.details;
      }
      response.statusCode = httpStatusCodeInternalServerError;

      await response.send(
        jsonEncode({
          'error': {'code': errorCode, 'message': message, 'details': ?details},
        }),
      );
    }
  }
}

/// A [CallRequest] adapted from a raw [ExpressHttpRequest], used to run a
/// [CallHandler] against a plain HTTP request (mainly for testing).
class CallRequestFromExpress with CallRequestMixin {
  /// The underlying HTTP request this [CallRequest] is adapted from.
  final ExpressHttpRequest request;

  /// The request payload, taken from [request]'s body.
  @override
  late final Object? data;

  /// The string representation of [data], or `null` if [data] is `null`.
  @override
  String? get text => data?.toString();

  /// Creates a [CallRequest] wrapping [request], reading [data] from its
  /// body.
  CallRequestFromExpress({required this.request}) {
    data = request.body;
  }

  /// Always throws, since a [CallContext] (Firebase Auth context) is not
  /// available when a call is adapted from a plain HTTP request.
  @override
  CallContext get context =>
      throw UnimplementedError('Cannot call context in a http call');
}

/// Adapts [callHandler] into a [RequestHandler] usable with
/// [HttpsFunctions.onRequest], by delegating to
/// [ExpressHttpRequestFfExt.handleWithCallHandler].
///
/// Returns a [RequestHandler] that, when invoked, calls [callHandler] with
/// a [CallRequest] built from the incoming raw request and writes its
/// result (or error) as the HTTP response.
RequestHandler onCallHandlerAsRequestHandler(CallHandler callHandler) {
  Future httpRequestHandler(ExpressHttpRequest request) async {
    return request.handleWithCallHandler(callHandler);
  }

  return httpRequestHandler;
}

/*
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
 */

var _map = {
  httpStatusCodeNotFound: HttpsErrorCode.notFound,
  httpStatusCodeUnauthorized: HttpsErrorCode.unauthenticated,
  httpStatusCodeForbidden: HttpsErrorCode.permissionDenied,
  httpStatusCodeInternalServerError: HttpsErrorCode.internal,
};

var _statusCodeMap = Map<int, String>.from(_map)..addAll({});
var _httpsErrorCodeMap = Map<String, int>.from(
  _map.map((k, v) => MapEntry(v, k)),
)..addAll({});

/// Converts an [HttpsErrorCode] value to an HTTP status code.
///
/// [errorCode] is expected to be one of the [HttpsErrorCode] constants.
/// Returns the matching HTTP status code, or `httpStatusCodeInternalServerError`
/// (500, from `package:tekartik_http`) if [errorCode] has no known
/// mapping.
int httpsErrorCodeToStatusCode(String errorCode) {
  return _httpsErrorCodeMap[errorCode] ?? httpStatusCodeInternalServerError;
}

var _statusHttpCodeMap = {
  'NOT_FOUND': HttpsErrorCode.notFound,
  'UNAUTHENTICATED': HttpsErrorCode.permissionDenied,
  'INTERNAL': HttpsErrorCode.internal,
};
var _statusCodeHttpMap = {
  for (var e in _statusHttpCodeMap.entries) e.value: e.key,
};

/// Converts an [HttpsErrorCode] value to the canonical uppercase status
/// name used in the wire format of function-to-function HTTP error
/// responses (e.g. `'NOT_FOUND'`, `'UNAUTHENTICATED'`, `'INTERNAL'`).
///
/// [errorCode] is expected to be one of the [HttpsErrorCode] constants.
/// Returns `'INTERNAL'` if [errorCode] has no known mapping.
String statusErrorCodeToHttpStatusCode(String errorCode) {
  return _statusCodeHttpMap[errorCode] ?? 'INTERNAL';
}

String httpStatusCodeToStatusErrorCode(String errorCode) {
  return _statusHttpCodeMap[errorCode] ?? HttpsErrorCode.internal;
}

/// Converts an [HttpsError] to the wire JSON format used for error
/// responses between functions.
extension HttpsErrorHttpExt on HttpsError {
  /// Returns a `{'status': ..., 'message': ..., 'details': ...}` map,
  /// where `status` is the canonical uppercase status name (see
  /// [statusErrorCodeToHttpStatusCode]) matching [HttpsError.code].
  Map<String, Object?> toHttpJson() {
    return {
      'status': statusErrorCodeToHttpStatusCode(code),
      'message': message,
      'details': details,
    };
  }
}

/// Converts an HTTP status code to an [HttpsErrorCode] value.
///
/// [statusCode] is a standard HTTP status code (e.g. 404, 401, 403, 500).
/// Returns the matching [HttpsErrorCode] constant, or
/// [HttpsErrorCode.internal] if [statusCode] has no known mapping.
String statusCodeToHttpsErrorCode(int statusCode) {
  return _statusCodeMap[statusCode] ?? HttpsErrorCode.internal;
}

/// Converts an [HttpClientException] (a failed HTTP call to another
/// function or service) into an [HttpsError].
extension HttpClientExceptionFirebaseFunctionsExt on HttpClientException {
  /// Converts this exception to an [HttpsError].
  ///
  /// If the response body decodes to the standard
  /// `{'error': {'status': ..., 'message': ..., 'details': ...}}` JSON
  /// error format, the resulting [HttpsError] uses that status/message/
  /// details. Otherwise it falls back to an [HttpsError] derived from the
  /// HTTP status code, this exception's string representation, and the raw
  /// response body as details.
  ///
  /// [stackTrace] is currently unused but accepted for future use /
  /// call-site context.
  HttpsError toHttpsError({StackTrace? stackTrace}) {
    try {
      var body = response.body;
      // {\"error\":{\"details\":\"command not-found\",\"message\":\"Not found\",\"status\":\"NOT_FOUND\"}}
      var map = body.jsonToMap();
      var error = map['error'];
      if (error is Map) {
        var status = error['status']?.toString();
        var message = error['message']?.toString();
        var details = error['details'];
        return HttpsError(
          _statusHttpCodeMap[status] ?? statusCodeToHttpsErrorCode(statusCode),
          message ?? '',
          details,
        );
      }
    } catch (_) {}

    return HttpsError(
      statusCodeToHttpsErrorCode(statusCode),
      '$this',
      response.body,
    );
  }
}

/// Converts any exception [e] into an [HttpsError], so it can be reported
/// as a well-formed callable/HTTPS function error response.
///
/// If [e] is already an [HttpsError], it is returned as-is. If [e] is an
/// [HttpClientException], it is converted via
/// [HttpClientExceptionFirebaseFunctionsExt.toHttpsError]. Otherwise, an
/// [HttpsError] with [HttpsErrorCode.internal] is returned, using [e]'s
/// string representation as the message and [stackTrace] as the details.
HttpsError anyExceptionToHttpsError(Object e, {StackTrace? stackTrace}) {
  if (e is HttpsError) {
    return e;
  }
  if (e is HttpClientException) {
    return e.toHttpsError(stackTrace: stackTrace);
  }
  return HttpsError(HttpsErrorCode.internal, '$e', stackTrace);
}

/// Converts [error] to its wire JSON map representation.
///
/// Deprecated, use [HttpsErrorHttpExt.toHttpJson] instead.
@Deprecated('Use toHttpJson instead')
Map<String, Object?> httpsErrorToJsonMap(HttpsError error) {
  return error.toHttpJson();
}

/// Builds an [HttpsError] from a decoded wire JSON [map] (as produced by
/// [HttpsErrorHttpExt.toHttpJson]).
///
/// [map] is expected to contain `'status'`, `'message'` and `'details'`
/// entries; each is optional. A missing/non-string `'status'` maps to
/// [HttpsErrorCode.internal], and a missing `'message'` defaults to
/// `'no message'`.
HttpsError httpsErrorFromJsonMap(Map map) {
  var httpStatusCode = httpStatusCodeToStatusErrorCode(
    map['status']?.toString() ?? '',
  );
  return HttpsError(
    httpStatusCode,
    map['message']?.toString() ?? 'no message',
    map['details'],
  );
}

// /**
//  * The set of Firebase Functions status codes. The codes are the same at the
//  * ones exposed by {@link https://github.com/grpc/grpc/blob/master/doc/statuscodes.md | gRPC}.
//  *
//  * @remarks
//  * Possible values:
//  *
//  * - `cancelled`: The operation was cancelled (typically by the caller).
//  *
//  * - `unknown`: Unknown error or an error from a different error domain.
//  *
//  * - `invalid-argument`: Client specified an invalid argument. Note that this
//  *   differs from `failed-precondition`. `invalid-argument` indicates
//  *   arguments that are problematic regardless of the state of the system
//  *   (e.g. an invalid field name).
//  *
//  * - `deadline-exceeded`: Deadline expired before operation could complete.
//  *   For operations that change the state of the system, this error may be
//  *   returned even if the operation has completed successfully. For example,
//  *   a successful response from a server could have been delayed long enough
//  *   for the deadline to expire.
//  *
//  * - `not-found`: Some requested document was not found.
//  *
//  * - `already-exists`: Some document that we attempted to create already
//  *   exists.
//  *
//  * - `permission-denied`: The caller does not have permission to execute the
//  *   specified operation.
//  *
//  * - `resource-exhausted`: Some resource has been exhausted, perhaps a
//  *   per-user quota, or perhaps the entire file system is out of space.
//  *
//  * - `failed-precondition`: Operation was rejected because the system is not
//  *   in a state required for the operation's execution.
//  *
//  * - `aborted`: The operation was aborted, typically due to a concurrency
//  *   issue like transaction aborts, etc.
//  *
//  * - `out-of-range`: Operation was attempted past the valid range.
//  *
//  * - `unimplemented`: Operation is not implemented or not supported/enabled.
//  *
//  * - `internal`: Internal errors. Means some invariants expected by
//  *   underlying system has been broken. If you see one of these errors,
//  *   something is very broken.
//  *
//  * - `unavailable`: The service is currently unavailable. This is most likely
//  *   a transient condition and may be corrected by retrying with a backoff.
//  *
//  * - `data-loss`: Unrecoverable data loss or corruption.
//  *
//  * - `unauthenticated`: The request does not have valid authentication
//  *   credentials for the operation.
//  */
// export type FunctionsErrorCode = "ok" | "cancelled" | "unknown" | "invalid-argument" | "deadline-exceeded" | "not-found" | "already-exists" | "permission-denied" | "resource-exhausted" | "failed-precondition" | "aborted" | "out-of-range" | "unimplemented" | "internal" | "unavailable" | "data-loss" | "unauthenticated";
// /** @hidden */
// export type CanonicalErrorCodeName = "OK" | "CANCELLED" | "UNKNOWN" | "INVALID_ARGUMENT" | "DEADLINE_EXCEEDED" | "NOT_FOUND" | "ALREADY_EXISTS" | "PERMISSION_DENIED" | "UNAUTHENTICATED" | "RESOURCE_EXHAUSTED" | "FAILED_PRECONDITION" | "ABORTED" | "OUT_OF_RANGE" | "UNIMPLEMENTED" | "INTERNAL" | "UNAVAILABLE" | "DATA_LOSS";
