import 'package:tekartik_firebase_functions/utils.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_http/src/import.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  group('onCallHandlerAsRequestHandler', () {
    late HttpServer server;
    late Uri baseUri;
    setUpAll(() async {
      var app = newFirebaseAppLocal(
        options: FirebaseAppOptions(projectId: 'adapter'),
      );
      var functions = firebaseFunctionsServiceMemory.functions(app);
      functions['map'] = functions.https.onRequest(
        onCallHandlerAsRequestHandler(
          (request) async => request.getRequestAsMap(),
        ),
      );
      functions['httpserror'] = functions.https.onRequest(
        onCallHandlerAsRequestHandler(
          (request) async => throw HttpsError(
            HttpsErrorCode.invalidArgument,
            'bad',
            'details',
          ),
        ),
      );
      functions['exception'] = functions.https.onRequest(
        onCallHandlerAsRequestHandler(
          (request) async => throw StateError('oops'),
        ),
      );
      server = await functions.serveHttp(port: 0);
      baseUri = httpServerGetUri(server);
    });
    tearDownAll(() async {
      await server.close();
    });

    Future<(int, Object?)> post(String name) async {
      var client = httpClientFactoryMemory.newClient();
      try {
        var response = await client
            .post(
              baseUri.resolve(name),
              headers: {httpHeaderContentType: httpContentTypeJson},
              body: jsonEncode({'a': 1}),
            )
            .timeout(const Duration(seconds: 5));
        return (response.statusCode, jsonDecode(response.body));
      } finally {
        client.close();
      }
    }

    test('request map', () async {
      var (statusCode, body) = await post('map');
      expect(statusCode, 200);
      expect(body, {'a': 1});
    });
    test('https error', () async {
      var (statusCode, body) = await post('httpserror');
      expect(statusCode, 400);
      expect(body, {
        'error': {
          'status': 'INVALID_ARGUMENT',
          'message': 'bad',
          'details': 'details',
        },
      });
    });
    test('exception', () async {
      var (statusCode, body) = await post('exception');
      expect(statusCode, 500);
      expect((body as Map)['error'], containsPair('status', 'INTERNAL'));
    });
  });
}
