import 'package:cv/cv_json.dart';
import 'package:tekartik_firebase_functions/utils.dart';
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
