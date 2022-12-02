import 'dart:convert';

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
      var reponseString = result is String ? result : jsonEncode(result);
      await response.send(reponseString);
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

      await response.send(jsonEncode({
        'error': {
          'code': errorCode,
          'message': message,
          if (details != null) 'details': details
        }
      }));
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

int httpsErrorCodeToStatusCode(String errorCode) {
  switch (errorCode) {
    case HttpsErrorCode.notFound:
      return httpStatusCodeNotFound;
    case HttpsErrorCode.permissionDenied:
      return httpStatusCodeUnauthorized;
  }
  return httpStatusCodeInternalServerError;
}
