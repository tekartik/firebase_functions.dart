import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:test/test.dart';
import 'package:tekartik_http_io/http_client_io.dart';

import 'package:tekartik_firebase_functions/firebase_functions.dart';

echoHandler(ExpressHttpRequest request) {
  print("request.url ${request.uri}");
  // print("request.originalUrl ${request.requestedUri}");
  request.response.write(requestBodyAsText(request.body));
  // request.response.writeln("uri: ${request.uri}");
  // request.response.writeln("requestedUri: ${request.requestedUri}");
  request.response.close();
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
        server = await serve(port: 0);
      });

      test('post', () async {
        var client = httpClientFactory.newClient();
        var response = await client.post('http://127.0.0.1:${server.port}/echo',
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
