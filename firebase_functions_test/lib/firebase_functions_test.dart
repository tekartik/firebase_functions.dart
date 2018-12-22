import 'package:tekartik_http/http.dart';
import 'package:test/test.dart';
import 'package:meta/meta.dart';

void main(
    {@required HttpClientFactory httpClientFactory, @required String baseUrl}) {
  test('post', () async {
    var client = httpClientFactory.newClient();
    var response = await client.post('${baseUrl}/echo', body: 'hello');
    expect(response.statusCode, 200);
    expect(response.contentLength, greaterThan(0));
    expect(response.body, equals('hello'));

    client.close();
  });

  test('queryParams', () async {
    var client = httpClientFactory.newClient();
    var response = await client.get('${baseUrl}/echoQuery?dev&param=value');
    expect(response.statusCode, 200);
    expect(response.body, 'dev&param=value');

    client.close();
  });

  test('fragment', () async {
    var client = httpClientFactory.newClient();
    var response = await client.get('${baseUrl}/echoFragment#some_fragment');
    expect(response.statusCode, 200);
    // Server has no fragment
    expect(response.body, '');
    client.close();
  });

  test('redirect', () async {
    var client = httpClientFactory.newClient();
    var response = await client.post('${baseUrl}/redirect', body: 'hello');
    expect(response.statusCode, 302);
    // no echo
    expect(response.body, '');
    expect(response.headers['location'], '$baseUrl/echo');
    client.close();
  });
}
