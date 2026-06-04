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

var _statusCodeMap = Map<int, String>.from(_map)..addAll({});

/// Convert status code to https error code
String statusCodeToHttpsErrorCode(int statusCode) {
  return _statusCodeMap[statusCode] ?? HttpsErrorCode.internal;
}

/// Convert to http exception
extension HttpClientExceptionFirebaseFunctionsExt on HttpClientException {
  /// Convert to https error
  HttpsError toHttpsError({StackTrace? stackTrace}) {
    return HttpsError(
      statusCodeToHttpsErrorCode(statusCode),
      '$this',
      response.body,
    );
  }
}
