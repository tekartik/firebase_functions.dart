@TestOn('vm')
library tekartik_firebase_functions_http.test.firebase_functions_test;

import 'dart:async';

import 'package:tekartik_firebase_functions_http/firebase_functions_test_context_memory.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart'
    as common;
import 'package:tekartik_http_io/http_client_io.dart';
import 'package:test/test.dart';

/// Memory for inner communication, http for outer
class FirebaseFunctionsTestContextMemoryIo
    extends FirebaseFunctionsTestContextMemory {
  FirebaseFunctionsTestContextMemoryIo()
      : super(httpClientFactory: httpClientFactoryIo);
}

/// Uses memory for internal communication and http for external communication
Future main() async {
  var context = FirebaseFunctionsTestContextMemoryIo();

  context = setup(
    testContext: context,
  );
  var server = await context.serve();
  //server.baseUrl = 'http://localhost:${server.port}';

  group('firebase_functions_memory_io', () {
    group('echo', () {
      setUpAll(() async {});

      common.ffTest(testContext: context);
      tearDownAll(() async {
        await server.close();
      });
    });
  });
}
