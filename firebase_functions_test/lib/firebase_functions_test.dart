import 'dart:typed_data';

import 'package:tekartik_firebase_functions_test/src/firebase_functions_test_context.dart';
import 'package:tekartik_http/http.dart'; // ignore: depend_on_referenced_packages
import 'package:test/test.dart';

import 'src/import.dart';

export 'src/firebase_functions_test_context.dart';

void ffTest(
    {required FirebaseFunctionsTestContext testContext,
    HttpClientFactory? httpClientFactory,
    String? baseUrl}) {
  setUp(() async {
    httpClientFactory ??= testContext.httpClientFactory;
  });
  test('post', () async {
    var client = httpClientFactory!.newClient();
    // devPrint('url: ${testContext.url('echo')}');
    var response =
        await client.post(Uri.parse(testContext.url('echo')), body: 'hello');
    expect(response.statusCode, 200);
    expect(response.contentLength, greaterThan(0));
    expect(response.body, equals('hello'));

    client.close();
  });

  test('echoBytes', () async {
    var client = httpClientFactory!.newClient();
    var response = await client.post(Uri.parse(testContext.url('echoBytes')),
        body: Uint8List.fromList([1, 2, 3]));
    expect(response.statusCode, 200);
    expect(response.contentLength, greaterThan(0));
    expect(response.bodyBytes, [1, 2, 3]);

    client.close();
  });

  test('queryParams', () async {
    var client = httpClientFactory!.newClient();
    var response = await client
        .get(Uri.parse(testContext.url('echoQuery?dev&param=value')));
    expect(response.statusCode, 200);
    expect(response.body, 'dev&param=value');

    client.close();
  });

  test('fragment', () async {
    var client = httpClientFactory!.newClient();
    var response = await client
        .get(Uri.parse(testContext.url('echoFragment#some_fragment')));
    expect(response.statusCode, 200);
    // Server has no fragment
    expect(response.body, '');
    client.close();
  });

  test('headers', () async {
    var client = httpClientFactory!.newClient();
    var response = await client.get(Uri.parse(testContext.url('echoHeaders')),
        headers: {'x-test1': 'value1'});
    expect(response.statusCode, 200);
    // Server has no fragment
    expect(response.body,
        startsWith('name: value1')); // don't care about line feed
    client.close();
  });

  test('redirect', () async {
    var client = httpClientFactory!.newClient();
    var response = await client.post(Uri.parse(testContext.url('redirect')),
        body: 'hello');
    expect(response.statusCode, 302);
    // no echo
    expect(response.body, '');
    expect(response.headers['location'], '$baseUrl/echo');
    client.close();
  }, skip: true);
}
