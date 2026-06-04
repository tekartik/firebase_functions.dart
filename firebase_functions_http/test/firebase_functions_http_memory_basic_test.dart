library;

import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_http/src/import.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() async {
  late Uri uri;
  late HttpServer server;
  late FirebaseFunctionsTestClientContext testClientContext;
  setUpAll(() async {
    var app = newFirebaseAppMemory();
    var httpClientFactory = httpClientFactoryMemory;
    var prefix = 'memory';
    var firebaseFunctions = firebaseFunctionsServiceMemory.functions(app);

    initFunctionsBasic(firebaseFunctions, prefix: prefix);
    server = await firebaseFunctions.serveHttp(port: 0);
    var serverUri = httpServerGetUri(server);

    var firebaseFunctionsCall = firebaseFunctionsCallServiceMemory
        .functionsCall(
          app,
          options: FirebaseFunctionsCallOptions(region: regionBelgium),
        );

    testClientContext = FirebaseFunctionsTestClientContext.urlTemplate(
      httpClientFactory: httpClientFactory,
      urlTemplate: '$serverUri$prefix{{function}}',
      functionsCall: firebaseFunctionsCall,
    );

    uri = Uri.parse(testClientContext.url('basic'));
  });
  test('uri', () {
    expect(uri.toString(), 'http://_memory:${server.port}/memorybasic');
  });

  basicTestGroup(() => testClientContext);
  tearDownAll(() async {
    await server.close();
    await testClientContext.close();
  });
}
