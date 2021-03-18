library tekartik_firebase_functions_http.test.firebase_functions_memory_test;

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_http/src/import.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

void echoHandler(ExpressHttpRequest request) {
  // print("request.url ${request.uri}");
  //request.response.write(requestBodyAsText(request.body));
  //request.response.close();
  request.response.send(requestBodyAsText(request.body));
}

void main() {
  var firebaseFunctions = firebaseFunctionsMemory;
  var httpClientFactory = httpClientFactoryMemory;
  testHttp(
      firebaseFunctions: firebaseFunctions,
      httpClientFactory: httpClientFactory);
}

void testHttp(
    {@required FirebaseFunctionsHttp firebaseFunctions,
    @required HttpClientFactory httpClientFactory}) {
  group('firebase_functions_io', () {
    group('echo', () {
      HttpServer server;

      setUpAll(() async {
        firebaseFunctions['echo'] =
            firebaseFunctions.https.onRequest(echoHandler);

        server = await firebaseFunctions.serveHttp(port: 0);
      });

      test('post', () async {
        var client = httpClientFactory.newClient();
        var response = await client.post(
            Uri.parse(p.url.join(httpServerGetUri(server).toString(), 'echo')),
            body: 'hello');
        expect(response.statusCode, 200);
        expect(response.contentLength, greaterThan(0));
        expect(response.body, equals('hello'));

        client.close();
      });

      tearDownAll(() async {
        await server.close();
      });
    });
  });
}
