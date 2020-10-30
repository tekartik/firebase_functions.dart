@TestOn('vm')
library tekartik_firebase_functions_io.test.firebase_functions_test;

import 'dart:async';

import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart'
    as common;
import 'package:test/test.dart';

Future main() async {
  var testContext = setup<FirebaseFunctionsTestContext>(testContext: null);

  var server = await testContext.serve();

  // context.baseUrl = 'http://localhost:${server.port}';

  group('firebase_functions_memory', () {
    group('common', () {
      setUpAll(() async {});

      common.main(testContext: testContext);
      tearDownAll(() async {
        await server.close();
      });
    });
  });
}
