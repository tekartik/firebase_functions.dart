import 'dart:convert';

import 'package:cv/cv_json.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_http/http.dart';

extension CallRequestFfExt on CallRequest {
  /// Get the request as a map
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

extension ExpressHttpRequestFfExt on ExpressHttpRequest {
  /// Wrap http request (mainly for http test)
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

/// Call request from http request
class CallRequestFromExpress with CallRequestMixin {
  final ExpressHttpRequest request;
  @override
  late final Object? data;

  @override
  String? get text => data?.toString();

  CallRequestFromExpress({required this.request}) {
    data = request.body;
  }

  @override
  CallContext get context =>
      throw UnimplementedError('Cannot call context in a http call');
}

/// Handler call handler as request handler
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
  httpStatusCodeUnauthorized: HttpsErrorCode.permissionDenied,
  httpStatusCodeInternalServerError: HttpsErrorCode.internal,
};

var _statusCodeMap = Map<int, String>.from(_map)..addAll({});
var _httpsErrorCodeMap = Map<String, int>.from(
  _map.map((k, v) => MapEntry(v, k)),
)..addAll({});

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

String statusErrorCodeToHttpStatusCode(String errorCode) {
  return _statusCodeHttpMap[errorCode] ?? 'INTERNAL';
}

String httpStatusCodeToStatusErrorCode(String errorCode) {
  return _statusHttpCodeMap[errorCode] ?? HttpsErrorCode.internal;
}

extension HttpsErrorHttpExt on HttpsError {
  Map<String, Object?> toHttpJson() {
    return {
      'status': statusErrorCodeToHttpStatusCode(code),
      'message': message,
      'details': details,
    };
  }
}

String statusCodeToHttpsErrorCode(int statusCode) {
  return _statusCodeMap[statusCode] ?? HttpsErrorCode.internal;
}

/// Convert to http exception

/// Convert to http exception
extension HttpClientExceptionFirebaseFunctionsExt on HttpClientException {
  /// Convert to https error
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

HttpsError anyExceptionToHttpsError(Object e, {StackTrace? stackTrace}) {
  if (e is HttpsError) {
    return e;
  }
  if (e is HttpClientException) {
    return e.toHttpsError(stackTrace: stackTrace);
  }
  return HttpsError(HttpsErrorCode.internal, '$e', stackTrace);
}

/// Https error to map
@Deprecated('Use toHttpJson instead')
Map<String, Object?> httpsErrorToJsonMap(HttpsError error) {
  return error.toHttpJson();
}

/// Https error from map
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
