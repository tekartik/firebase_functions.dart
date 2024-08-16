library;

import 'package:path/path.dart' as p;
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_http/src/import.dart';
import 'package:tekartik_firebase_functions_http/test/firebase_functions_test_context_memory.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void echoHandler(ExpressHttpRequest request) {
  // print("request.url ${request.uri}");
  //request.response.write(requestBodyAsText(request.body));
  //request.response.close();
  request.response.send(requestBodyAsText(request.body));
}

void main() {
  var dummyProjectId = 'dummyproject';
  var app = newFirebaseAppLocal(
      options: FirebaseAppOptions(projectId: dummyProjectId));

  var firebaseFunctions = firebaseFunctionsServiceMemory.functions(app);
  var firebaseFunctionsCallService = firebaseFunctionsCallServiceMemory;
  var firebaseFunctionsCall =
      firebaseFunctionsCallService.functionsCall(app, region: 'dummy');
  var httpClientFactory = httpClientFactoryMemory;

  group('firebase_functions_memory', () {
    testHttp(
        firebaseFunctions: firebaseFunctions,
        httpClientFactory: httpClientFactory);
    group('common', () {
      var context = FirebaseFunctionsTestContextMemory(
        firebaseFunctions: firebaseFunctions,

        /// Set initially to trigger testing but changed later
        functionsCall: firebaseFunctionsCall,
      );

      context = setup(
        testContext: context,
      );

      //server.baseUrl = 'http://localhost:${server.port}';

      late FfServer ffServer;
      setUpAll(() async {
        ffServer = await context.serve();
        var firebaseFunctionsCall = firebaseFunctionsCallService
            .functionsCall(app, region: regionBelgium, baseUri: ffServer.uri);
        context.functionsCall = firebaseFunctionsCall;
      });

      ffTest(testContext: context, projectId: dummyProjectId);
      tearDownAll(() async {
        await ffServer.close();
      });
    });
  });
}

void testHttp(
    {required FirebaseFunctionsHttp firebaseFunctions,
    required HttpClientFactory httpClientFactory}) {
  group('custom', () {
    group('echo', () {
      HttpServer? server;

      setUpAll(() async {
        firebaseFunctions['echo'] =
            firebaseFunctions.https.onRequest(echoHandler);
        firebaseFunctions['echov2'] =
            firebaseFunctions.https.onRequestV2(HttpsOptions(), echoHandler);

        server = await firebaseFunctions.serveHttp(port: 0);
      });

      test('echo', () async {
        var client = httpClientFactory.newClient();
        var response = await client.post(
            Uri.parse(p.url.join(httpServerGetUri(server!).toString(), 'echo')),
            body: 'hello');
        expect(response.statusCode, 200);
        expect(response.contentLength, greaterThan(0));
        expect(response.body, equals('hello'));

        client.close();
      });
      test('echov2', () async {
        var client = httpClientFactory.newClient();
        var response = await client.post(
            Uri.parse(
                p.url.join(httpServerGetUri(server!).toString(), 'echov2')),
            body: 'hello');
        expect(response.statusCode, 200);
        expect(response.contentLength, greaterThan(0));
        expect(response.body, equals('hello'));

        client.close();
      });

      tearDownAll(() async {
        await server!.close();
      });
    });
  });
}
