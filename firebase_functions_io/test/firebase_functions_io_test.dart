@TestOn('vm')
library tekartik_firebase_functions_io.test.firebase_functions_io_test;

import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:test/test.dart';
import 'package:tekartik_http_io/http_client_io.dart';

import 'package:tekartik_firebase_functions/firebase_functions.dart';

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
        server = await serve(port: 0);
      });

      test('post', () async {
        var client = httpClientFactory.newClient();
        var response = await client.post('http://localhost:${server.port}/echo',
            body: 'hello');
        expect(response.statusCode, 200);
        expect(response.contentLength, greaterThan(0));
        expect(response.body, equals('hello'));

        client.close();
      });

      test('queryParams', () async {
        var client = httpClientFactory.newClient();
        var response = await client
            .get('http://localhost:${server.port}/echoQuery?dev&param=value');
        expect(response.statusCode, 200);
        expect(response.body, 'dev&param=value');

        client.close();
      });

      test('fragment', () async {
        var client = httpClientFactory.newClient();
        var response = await client
            .get('http://localhost:${server.port}/echoFragment#some_fragment');
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
