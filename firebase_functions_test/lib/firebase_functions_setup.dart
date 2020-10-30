import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_test_context_memory.dart';

import 'src/import.dart';

export 'package:tekartik_firebase_functions_http/firebase_functions_test_context_memory.dart';

void echoBytesHandler(ExpressHttpRequest request) {
  // devPrint('request.body ${request.body?.runtimeType}: ${request.body}');
  request.response.send(request.body as Uint8List);
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

class TestContext {
  String baseUrl;
}

T setup<T extends FirebaseFunctionsTestContext>(
    {@required T testContext,
    FirebaseFunctions firebaseFunctions,
    TestContext context}) {
  testContext ??= FirebaseFunctionsTestContextMemory() as T;
  firebaseFunctions ??= testContext.firebaseFunctions;

  void redirectFragmentHandler(ExpressHttpRequest request) {
    // print("request.url ${request.uri} ${request.uri.fragment}");
    request.response.redirect(Uri.parse(testContext.url('echo')));
  }

  firebaseFunctions['echo'] = firebaseFunctions.https.onRequest(echoHandler);
  firebaseFunctions['redirect'] =
      firebaseFunctions.https.onRequest(redirectFragmentHandler);
  firebaseFunctions['echoQuery'] =
      firebaseFunctions.https.onRequest(echoQueryHandler);
  firebaseFunctions['echoBytes'] =
      firebaseFunctions.https.onRequest(echoBytesHandler);
  firebaseFunctions['echoFragment'] =
      firebaseFunctions.https.onRequest(echoFragmentHandler);
  return testContext;
}
