import 'package:tekartik_firebase_functions_http/src/import.dart';
import 'package:tekartik_firebase_functions_http/test/firebase_functions_test_context_http.dart';
import 'package:test/test.dart';

void main() {
  group('test_context', () {
    test('client', () {
      var client = FirebaseFunctionsTestClientContextHttp(
        httpClientFactory: httpClientFactoryMemory,
        baseUrl: 'https://localhost:5000/test',
      );
      expect(client.url('echo'), 'https://localhost:5000/test/echo');

      client = FirebaseFunctionsTestClientContextHttp(
        httpClientFactory: httpClientFactoryMemory,
        baseUrl: 'https://{{function}}-xxxxx.run.app',
      );
      expect(client.url('echo'), 'https://echo-xxxxx.run.app');
      expect(client.url('echo?test'), 'https://echo-xxxxx.run.app/?test');
      expect(
        client.url('echo/sub?test'),
        'https://echo-xxxxx.run.app/sub?test',
      );
    });
  });
}
