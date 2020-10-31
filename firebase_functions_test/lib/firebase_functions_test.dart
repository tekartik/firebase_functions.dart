import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_test_context_memory.dart';
import 'package:tekartik_firebase_functions_test/src/import.dart';
import 'package:tekartik_http/http.dart';
import 'package:test/test.dart';

import 'firebase_functions_setup.dart';

void main(
    {@required FirebaseFunctionsTestContext testContext,
    HttpClientFactory httpClientFactory,
    String baseUrl}) {
  setUp(() async {
    if (testContext == null) {
      testContext = FirebaseFunctionsTestContextMemory();
      testContext = setup(testContext: testContext);
      await testContext.serve();
    }
    httpClientFactory ??= testContext.httpClientFactory;
  });
  test('post', () async {
    var client = httpClientFactory.newClient();
    // devPrint('url: ${testContext.url('echo')}');
    var response = await client.post(testContext.url('echo'), body: 'hello');
    expect(response.statusCode, 200);
    expect(response.contentLength, greaterThan(0));
    expect(response.body, equals('hello'));

    client.close();
  });

  test('echoBytes', () async {
    var client = httpClientFactory.newClient();
    var response = await client.post(testContext.url('echoBytes'),
        body: Uint8List.fromList([1, 2, 3]));
    expect(response.statusCode, 200);
    expect(response.contentLength, greaterThan(0));
    expect(response.bodyBytes, [1, 2, 3]);

    client.close();
  });

  test('queryParams', () async {
    var client = httpClientFactory.newClient();
    var response =
        await client.get(testContext.url('echoQuery?dev&param=value'));
    expect(response.statusCode, 200);
    expect(response.body, 'dev&param=value');

    client.close();
  });

  test('fragment', () async {
    var client = httpClientFactory.newClient();
    var response =
        await client.get(testContext.url('echoFragment#some_fragment'));
    expect(response.statusCode, 200);
    // Server has no fragment
    expect(response.body, '');
    client.close();
  });

  test('redirect', () async {
    var client = httpClientFactory.newClient();
    var response =
        await client.post(testContext.url('redirect'), body: 'hello');
    expect(response.statusCode, 302);
    // no echo
    expect(response.body, '');
    expect(response.headers['location'], '$baseUrl/echo');
    client.close();
  }, skip: true);
}
