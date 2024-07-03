import 'dart:typed_data';

import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_test/src/firebase_functions_test_context.dart';
import 'package:tekartik_firebase_functions_test/src/import.dart';

import 'constants.dart';

void echoBytesHandler(ExpressHttpRequest request) {
  var body = request.body;
  //devPrint('echoBytes ${body?.runtimeType}: ${body}');
  request.response.headers.contentType = request.headers.contentType;
  request.response.send(body as Uint8List?);
}

void echoHandler(ExpressHttpRequest request) {
  // print("request.url ${request.uri}");
  //request.response.write(requestBodyAsText(request.body));
  //request.response.close();
  request.response.send(requestBodyAsText(request.body));
}

void echoQueryHandler(ExpressHttpRequest request) {
  // print("request.url ${request.uri} ${request.uri.queryParameters}");
  request.response.send(request.uri.query);
}

void echoFragmentHandler(ExpressHttpRequest request) {
  // print("request.url ${request.uri} ${request.uri.fragment}");
  request.response.send(request.uri.fragment);
}

void echoInfoHandler(ExpressHttpRequest request) {
  //request.response.headers.contentType = request.headers.contentType;
  request.response.headers.set(httpHeaderContentType, httpContentTypeJson);
  request.response
      .send({'method': request.method, 'uri': request.uri.toString()});
}

void infoHandler(FirebaseFunctions functions, ExpressHttpRequest request) {
  //request.response.headers.contentType = request.headers.contentType;
  request.response.headers.set(httpHeaderContentType, httpContentTypeJson);
  request.response.send({'projectId': functions.params.projectId});
}

void echoHeadersHandler(ExpressHttpRequest request) {
  // print("request.url ${request.uri} ${request.uri.fragment}");
  var sb = StringBuffer();
  request.headers.forEach((name, values) {
    sb.writeln('name: ${values.join(', ')}');
  });
  request.response.send(sb.toString());
}

FutureOr<Object?> callHandler(CallRequest request) async {
  //devPrint('request data ${request.text}');
  try {
    return {'uid': request.context.auth?.uid, 'data': request.data};
  } catch (_) {
    return {'error': 'no_body'};
  }
}

class TestContext {
  String? baseUrl;
}

T setup<T extends FirebaseFunctionsTestServerContext>(
    {required T testContext,
    FirebaseFunctions? firebaseFunctions,
    TestContext? context,
    String? testRedirectUrl}) {
  firebaseFunctions ??= testContext.firebaseFunctions;

  /// Not working not tested yet
  void redirectFragmentHandler(ExpressHttpRequest request) {
    // print("request.url ${request.uri} ${request.uri.fragment}");
    request.response.redirect(Uri.parse(testRedirectUrl!));
  }

  firebaseFunctions['echo'] = firebaseFunctions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), echoHandler);

  firebaseFunctions['redirect'] = firebaseFunctions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), redirectFragmentHandler);
  firebaseFunctions['echoquery'] = firebaseFunctions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), echoQueryHandler);
  firebaseFunctions['echobytes'] = firebaseFunctions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), echoBytesHandler);
  firebaseFunctions['echofragment'] = firebaseFunctions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), echoFragmentHandler);
  firebaseFunctions['echoheaders'] = firebaseFunctions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), echoHeadersHandler);
  firebaseFunctions['echoinfo'] = firebaseFunctions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), echoInfoHandler);
  firebaseFunctions['ffinfo'] = firebaseFunctions.https.onRequest(
      (request) => infoHandler(firebaseFunctions!, request),
      httpsOptions: HttpsOptions(cors: true, region: regionBelgium));

  /// temp out for node testing
  try {
    firebaseFunctions[functionCallName] = firebaseFunctions.https.onCall(
        callHandler,
        callableOptions:
            HttpsCallableOptions(cors: true, region: regionBelgium));
  } catch (e) {
    print('error onCall definition $e');
  }
  return testContext;
}

var testFunctionNames = [
  'echo',
  'redirect',
  'echoquery',
  'echobytes',
  'echofragment',
  'echoheaders',
  'echoinfo',
  'ffinfo',
  functionCallName
];
