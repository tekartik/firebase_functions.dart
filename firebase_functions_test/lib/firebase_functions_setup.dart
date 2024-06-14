import 'dart:typed_data';

import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_test/src/firebase_functions_test_context.dart';
import 'package:tekartik_firebase_functions_test/src/import.dart';

void echoBytesHandler(ExpressHttpRequest request) {
  var body = request.body;
  devPrint('echoBytes ${body?.runtimeType}: ${body}');
  devPrint('echoBytes: request.body ${body?.runtimeType}: ${body}');
  request.response.headers.contentType = request.headers.contentType;
  request.response.send(request.body as Uint8List?);
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

void echoHeadersHandler(ExpressHttpRequest request) {
  // print("request.url ${request.uri} ${request.uri.fragment}");
  var sb = StringBuffer();
  request.headers.forEach((name, values) {
    sb.writeln('name: ${values.join(', ')}');
  });
  request.response.send(sb.toString());
}

FutureOr<dynamic> callHandler(CallRequest request) async {
  //devPrint('request data ${request.text}');
  try {
    return jsonDecode(request.text!);
  } catch (_) {
    return {'error': 'no_body'};
  }
}

class TestContext {
  String? baseUrl;
}

T setup<T extends FirebaseFunctionsTestContext>(
    {required T testContext,
    FirebaseFunctions? firebaseFunctions,
    TestContext? context}) {
  firebaseFunctions ??= testContext.firebaseFunctions;

  void redirectFragmentHandler(ExpressHttpRequest request) {
    // print("request.url ${request.uri} ${request.uri.fragment}");
    request.response.redirect(Uri.parse(testContext.url('echo')));
  }

  firebaseFunctions['echo'] = firebaseFunctions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), echoHandler);

  firebaseFunctions['redirect'] = firebaseFunctions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), redirectFragmentHandler);
  firebaseFunctions['echoQuery'] = firebaseFunctions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), echoQueryHandler);
  firebaseFunctions['echoBytes'] = firebaseFunctions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), echoBytesHandler);
  firebaseFunctions['echoFragment'] = firebaseFunctions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), echoFragmentHandler);
  firebaseFunctions['echoHeaders'] = firebaseFunctions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), echoHeadersHandler);
  firebaseFunctions['echoInfo'] = firebaseFunctions.https.onRequestV2(
      HttpsOptions(cors: true, region: regionBelgium), echoInfoHandler);

  /// temp out for node testing
  try {
    firebaseFunctions['call'] = firebaseFunctions.https.onCall(callHandler);
  } catch (e) {
    print('error onCall definition $e');
  }
  return testContext;
}
