@TestOn('vm')
library tekartik_firebase_functions_io.test.firebase_functions_io_test;

import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_http_io/http_client_io.dart';
import 'package:test/test.dart';

import 'firebase_functions_memory_test.dart';

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

void main() {
  var firebaseFunctions = firebaseFunctionsIo;
  var httpClientFactory = httpClientFactoryIo;
  testHttp(
      firebaseFunctions: firebaseFunctions,
      httpClientFactory: httpClientFactory);
}
