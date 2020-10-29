library tekartik_firebase_functions_io.test.firebase_functions_memory_test;

import 'package:tekartik_firebase_functions_io/firebase_functions_memory.dart';
import 'package:test/test.dart';
import 'package:tekartik_http/http_memory.dart';

import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:path/path.dart' as p;
import 'package:meta/meta.dart';

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
        firebaseFunctions['echoQuery'] =
            firebaseFunctions.https.onRequest(echoQueryHandler);
        firebaseFunctions['echoFragment'] =
            firebaseFunctions.https.onRequest(echoFragmentHandler);
        server = await firebaseFunctions.serveHttp(port: 0);
      });

      test('post', () async {
        var client = httpClientFactory.newClient();
        var response = await client.post(
            p.url.join(httpServerGetUri(server).toString(), 'echo'),
            body: 'hello');
        expect(response.statusCode, 200);
        expect(response.contentLength, greaterThan(0));
        expect(response.body, equals('hello'));

        client.close();
      });

      test('queryParams', () async {
        var client = httpClientFactory.newClient();
        var response = await client.get(p.url.join(
            httpServerGetUri(server).toString(), 'echoQuery?dev&param=value'));
        expect(response.statusCode, 200);
        expect(response.body, 'dev&param=value');

        client.close();
      });

      test('fragment', () async {
        var client = httpClientFactory.newClient();
        var response = await client.get(p.url.join(
            httpServerGetUri(server).toString(), 'echoFragment#some_fragment'));
        expect(response.statusCode, 200);
        // Server has no fragment
        expect(response.body, '');
        client.close();
      });

      tearDownAll(() async {
        await server.close();
      });
    });
  });
}
