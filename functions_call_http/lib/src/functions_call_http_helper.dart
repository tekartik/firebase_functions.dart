import 'package:cv/cv_json.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_http/http.dart';
import 'package:tekartik_http/http.dart' as http;

/// Call a cloud function with the given [uri] and [parameters].
///
/// This method uses an HTTP request to call the cloud function. It is suitable for functions that are not callable (i.e., do not use the onCall trigger).
///
/// The [name] parameter specifies the name of the cloud function to call. The [parameters] parameter is an optional object that contains the data to send to the cloud function.
///
/// Returns a Future that resolves with the result of the cloud function call, or throws a [HttpsError] error if the call fails.
Future<FirebaseFunctionsCallableResult<T>> firebaseFunctionsHttpCallUri<T>(
  Client client,
  Uri uri, {
  Map<String, String>? headers,
  Object? parameters,
}) async {
  headers ??= <String, String>{};
  headers[http.httpHeaderContentType] = http.httpContentTypeJson;

  try {
    var text = await httpClientRead(
      client,
      httpMethodPost,
      uri,
      headers: headers,
      body: {'data': parameters}.cvToJson(),
    );
    var response = text.jsonToMap();
    var result = response['result'];
    var error = response['error'];
    if (error != null) {
      throw httpsErrorFromJsonMap(error as Map);
    }

    return FirebaseFunctionsCallableResult<T>(result as T);
  } catch (e, st) {
    var httpsError = anyExceptionToHttpsError(e, stackTrace: st);
    //devPrint('e: $e, httpsError: $httpsError');
    throw httpsError;
  }
}

/// Convert to http exception
HttpsError anyExceptionToHttpsError(Object e, {StackTrace? stackTrace}) {
  if (e is HttpsError) {
    return e;
  }
  if (e is HttpClientException) {
    return e.toHttpsError(stackTrace: stackTrace);
  }
  return HttpsError(HttpsErrorCode.internal, '$e', stackTrace);
}

/// Https error from map
HttpsError httpsErrorFromJsonMap(Map map) {
  // JSON
  // {
  //   "error": {
  //     "status": "INVALID_ARGUMENT",
  //     "message": "The password is too short.",
  //     "details": { "minCharacters": 8 }
  //   }
  // }
  return HttpsError(
    map['status']?.toString() ?? HttpsErrorCode.unavailable,
    map['message']?.toString() ?? 'no message',
    map['details'],
  );
}

var _map = {
  httpStatusCodeNotFound: HttpsErrorCode.notFound,
  httpStatusCodeUnauthorized: HttpsErrorCode.permissionDenied,
  httpStatusCodeInternalServerError: HttpsErrorCode.internal,
};

var _statusHttpCodeMap = {
  'NOT_FOUND': HttpsErrorCode.notFound,
  'UNAUTHENTICATED': HttpsErrorCode.permissionDenied,
  'INTERNAL': HttpsErrorCode.internal,
};

var _statusCodeMap = Map<int, String>.from(_map)..addAll({});

/// Convert status code to https error code
String statusCodeToHttpsErrorCode(int statusCode) {
  return _statusCodeMap[statusCode] ?? HttpsErrorCode.internal;
}

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
