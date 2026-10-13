@TestOn('vm')
library;

import 'dart:convert';

import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_http_io/http_client_io.dart';
import 'package:test/test.dart';

void main() {
  group('serve', () {
    late HttpServer server;
    late Uri baseUri;
    setUpAll(() async {
      var functions = firebaseFunctionsIo;
      functions['echo'] = functions.https.onRequest(
        (request) => request.response.send(request.bodyAsString),
      );
      functions['call'] = functions.https.onCall(
        (request) async => {'got': request.data},
      );
      server = await serve(port: 0);
      baseUri = Uri.parse('http://localhost:${server.port}/');
    });
    tearDownAll(() async {
      await server.close(force: true);
    });

    test('echo, call, not found', () async {
      var client = httpClientFactoryIo.newClient();
      try {
        var response = await client.post(
          baseUri.resolve('echo'),
          body: 'hello',
        );
        expect(response.body, 'hello');
        response = await client.post(
          baseUri.resolve('call'),
          headers: {httpHeaderContentType: httpContentTypeJson},
          body: jsonEncode({'data': 1}),
        );
        expect(jsonDecode(response.body), {
          'result': {'got': 1},
        });
        // Each request is handled on its own, / does not stop the server.
        for (var path in ['missing', '', 'missing']) {
          response = await client
              .get(baseUri.resolve(path))
              .timeout(const Duration(seconds: 5));
          expect(response.statusCode, 404, reason: path);
        }
        response = await client.post(baseUri.resolve('echo'), body: 'again');
        expect(response.body, 'again');
      } finally {
        client.close();
      }
    });
  });
}
