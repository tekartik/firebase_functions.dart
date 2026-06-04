@TestOn('vm')
library;

import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http_io/http_io.dart';
import 'package:test/test.dart';

void main() async {
  late FirebaseFunctionsTestClientContext testClientContext;
  late HttpServer server;
  late Uri uri;
  setUpAll(() async {
    var dummyProjectId = 'dummyproject';
    var app = newFirebaseAppLocal(
      options: FirebaseAppOptions(projectId: dummyProjectId),
    );
    var httpFactory = httpFactoryIo;

    var prefix = 'http';
    var firebaseFunctions = firebaseFunctionsServiceIo.functions(app);
    initFunctionsBasic(firebaseFunctions, prefix: prefix);
    server = await firebaseFunctions.serveHttp(port: 0);
    var serverUri = httpServerGetUri(server);

    var firebaseFunctionsCall = firebaseFunctionsCallServiceHttp.functionsCall(
      app,
      options: FirebaseFunctionsCallOptions(region: regionBelgium),
    );

    testClientContext = FirebaseFunctionsTestClientContext.urlTemplate(
      httpClientFactory: httpFactory.client,
      urlTemplate: '$serverUri$prefix{{function}}',
      functionsCall: firebaseFunctionsCall,
    );

    uri = Uri.parse(testClientContext.url('basic'));
  });
  test('uri', () {
    expect(uri.toString(), 'http://localhost:${server.port}/httpbasic');
  });

  basicTestGroup(() => testClientContext);
  tearDownAll(() async {
    await server.close();
    await testClientContext.close();
  });
}
