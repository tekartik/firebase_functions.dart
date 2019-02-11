@TestOn('vm')
library tekartik_firebase_functions_io.test.firebase_functions_test;

import 'dart:async';

import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart'
    as common;
import 'package:tekartik_http_io/http_client_io.dart';
import 'package:test/test.dart';

Future main() async {
  var firebaseFunctions = firebaseFunctionsIo;
  var httpClientFactory = httpClientFactoryIo;
  var context = TestContext();

  setup(
      firebaseFunctions: firebaseFunctions,
      httpClientFactory: httpClientFactory,
      context: context);
  var server = await serve(port: 0);
  context.baseUrl = 'http://localhost:${server.port}';

  group('firebase_functions_io', () {
    group('echo', () {
      setUpAll(() async {});

      common.main(
          httpClientFactory: httpClientFactory, baseUrl: context.baseUrl);
      tearDownAll(() async {
        await server.close();
      });
    });
  });
}
