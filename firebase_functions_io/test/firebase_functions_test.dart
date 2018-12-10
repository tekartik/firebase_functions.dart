@TestOn('vm')
library tekartik_firebase_functions_io.test.firebase_functions_test;

import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:test/test.dart';
import 'package:tekartik_http_io/http_client_io.dart';

import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart' as common;


Future main() async {
  var firebaseFunctions = firebaseFunctionsIo;
  var httpClientFactory = httpClientFactoryIo;

  setup(firebaseFunctions: firebaseFunctions, httpClientFactory: httpClientFactory);
  var server = await serve(port: 0);

  group('firebase_functions_io', () {
    group('echo', () {

      setUpAll(() async {

      });

      common.main(httpClientFactory: httpClientFactory, baseUrl: 'http://localhost:${server.port}');
      tearDownAll(() async {
        await server.close();
      });
    });
  });
}
