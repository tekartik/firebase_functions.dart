import 'dart:typed_data';

import 'package:tekartik_firebase_functions_test/src/firebase_functions_test_context.dart';

// ignore: depend_on_referenced_packages
import 'package:test/test.dart';

import 'src/import.dart';

export 'src/firebase_functions_test_context.dart';

void ffTest(
    {required FirebaseFunctionsTestClientContext testContext,
    HttpClientFactory? httpClientFactory,
    String? baseUrl}) {
  setUp(() async {
    httpClientFactory ??= testContext.httpClientFactory;
  });
  test('post', () async {
    var client = httpClientFactory!.newClient();
    var response =
        await client.post(Uri.parse(testContext.url('echo')), body: 'hello');
    expect(response.statusCode, 200);
    expect(response.contentLength, greaterThan(0));
    expect(response.body, equals('hello'));

    client.close();
  });

  test('echoBytes binary', () async {
    var client = httpClientFactory!.newClient();
    var response = await client.post(Uri.parse(testContext.url('echobytes')),
        body: Uint8List.fromList([1, 2, 3]),

        /// Needed for node
        headers: {httpHeaderContentType: httpContentTypeBytes});
    expect(response.statusCode, 200);
    expect(response.contentLength, greaterThan(0));
    expect(response.bodyBytes, [1, 2, 3]);
    // Not working memory/http expect(response.headers[httpHeaderContentType], httpContentTypeBytes);
    client.close();
  });

  test('echoBytes test', () async {
    var content = 'éàö';
    var client = httpClientFactory!.newClient();
    var response = await client.post(Uri.parse(testContext.url('echobytes')),
        body: content,

        /// Needed for node
        headers: {httpHeaderContentType: httpContentTypeText});
    expect(response.statusCode, 200);
    expect(response.contentLength, greaterThan(0));
    expect(utf8.decode(response.bodyBytes), content);
    expect(response.body, content);
    // Not working memory/http expect(response.headers[httpHeaderContentType], httpContentTypeText);

    client.close();
  });

  test('echoBytes json', () async {
    var map = {'test': 'éàö'};
    var client = httpClientFactory!.newClient();
    var response = await client.post(Uri.parse(testContext.url('echobytes')),
        body: jsonEncode(map),

        /// Needed for node
        headers: {httpHeaderContentType: httpContentTypeJson});
    expect(response.statusCode, 200);
    expect(response.contentLength, greaterThan(0));
    expect(jsonDecode(utf8.decode(response.bodyBytes)), map);
    expect(jsonDecode(response.body), map);
    // Not working memory/http expect(response.headers[httpHeaderContentType], httpContentTypeJson);

    client.close();
  });

  test('queryParams', () async {
    var client = httpClientFactory!.newClient();
    var response = await client
        .get(Uri.parse(testContext.url('echoquery?dev&param=value')));
    expect(response.statusCode, 200);
    expect(response.body, 'dev&param=value');

    client.close();
  });

  test('fragment', () async {
    var client = httpClientFactory!.newClient();
    var response = await client
        .get(Uri.parse(testContext.url('echofragment#some_fragment')));
    expect(response.statusCode, 200);
    // Server has no fragment
    expect(response.body, '');
    client.close();
  });

  test('info', () async {
    var client = httpClientFactory!.newClient();
    var response =
        await client.get(Uri.parse(testContext.url('echoinfo?param#fragment')));
    expect(response.statusCode, 200);
    // Server has no fragment
    var decoded = jsonDecode(response.body);
    try {
      expect(decoded, {'method': 'GET', 'uri': '?param#'});
    } catch (e) {
      // On node we have a leading /
      expect(decoded, {'method': 'GET', 'uri': '/?param'});
    }
    response = await client
        .post(Uri.parse(testContext.url('echoinfo/sub1/sub2?param#fragment')));
    expect(response.statusCode, 200);
    // Server has no fragment
    decoded = jsonDecode(response.body);
    try {
      expect(decoded, {'method': 'POST', 'uri': 'sub1/sub2?param#'});
    } catch (e) {
      // On node we have a leading /
      expect(decoded, {'method': 'POST', 'uri': '/sub1/sub2?param'});
    }

    client.close();
  });

  test('headers', () async {
    var client = httpClientFactory!.newClient();
    var response = await client.get(Uri.parse(testContext.url('echoheaders')),
        headers: {'x-test1': 'value1'});
    expect(response.statusCode, 200);
    // Server has no fragment
    // For http io we might have
    //              'name: Dart/3.4 (dart:io)\n'
    //             'name: value1\n'
    //             'name: gzip\n'
    //             'name: localhost:44295\n'
    //             ''
    expect(
        response.body, contains('name: value1')); // don't care about line feed
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
