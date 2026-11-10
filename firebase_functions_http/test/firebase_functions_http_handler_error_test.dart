import 'package:tekartik_firebase_functions/utils.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_http/src/import.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  // A failing handler used to be an uncaught error (the process exits), its
  // request never answered, a sync one stopped the server.
  group('handler error', () {
    late HttpServer server;
    late Uri baseUri;
    setUpAll(() async {
      var app = newFirebaseAppLocal(
        options: FirebaseAppOptions(projectId: 'handler_error'),
      );
      var functions = firebaseFunctionsServiceMemory.functions(app);
      functions['ok'] = functions.https.onRequest((request) async {
        await request.response.send('ok');
      });
      functions['async_throw'] = functions.https.onRequest((request) async {
        await Future<void>.delayed(Duration.zero);
        throw StateError('async handler error');
      });
      functions['sync_throw'] = functions.https.onRequest((request) {
        throw StateError('sync handler error');
      });
      functions['call_stack_trace'] = functions.https.onCall((request) {
        // Its details hold the stack trace (not JSON).
        throw anyExceptionToHttpsError(
          StateError('call error'),
          stackTrace: StackTrace.current,
        );
      });
      server = await functions.serveHttp(port: 0);
      baseUri = httpServerGetUri(server);
    });
    tearDownAll(() async {
      await server.close();
    });

    Future<(int, String)> post(String name, {Object? data}) async {
      var client = httpClientFactoryMemory.newClient();
      try {
        var response = await client
            .post(
              baseUri.resolve(name),
              headers: {httpHeaderContentType: httpContentTypeJson},
              body: jsonEncode({'data': data}),
            )
            .timeout(const Duration(seconds: 5));
        return (response.statusCode, response.body);
      } finally {
        client.close();
      }
    }

    test('async handler error answers 500, the server serves on', () async {
      var (statusCode, _) = await post('async_throw');
      expect(statusCode, httpStatusCodeInternalServerError);
      expect(await post('ok'), (200, 'ok'));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('sync handler error answers 500, the server serves on', () async {
      var (statusCode, _) = await post('sync_throw');
      expect(statusCode, httpStatusCodeInternalServerError);
      expect(await post('ok'), (200, 'ok'));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('callable error with a stack trace in its details', () async {
      var (statusCode, body) = await post('call_stack_trace');
      expect(statusCode, httpStatusCodeInternalServerError);
      var error = (jsonDecode(body) as Map)['error'] as Map;
      expect(error['status'], 'INTERNAL');
      expect(await post('ok'), (200, 'ok'));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
