import 'package:cv/cv_json.dart';
import 'package:dev_test/test.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart';
import 'package:tekartik_firebase_functions_test/src/import.dart';

void basicTestGroup(
  FirebaseFunctionsTestClientContext Function() getTestContext,
) {
  late FirebaseFunctionsCall functionsCall;
  late Uri uri;
  late FirebaseFunctionsCallable callable;
  late FirebaseFunctionsTestClientContext testContext;
  setUpAll(() {
    testContext = getTestContext();
    functionsCall = testContext.functionsCall!;
    uri = Uri.parse(testContext.url('basic'));
    callable = functionsCall.callableFromUri(uri);
  });

  test('basic echo', () async {
    expect(
      (await callable.call<Map>({
        'command': 'echo',
        'data': {'Hello': 'World'},
      })).data,
      {'Hello': 'World'},
    );
  });

  test('raw basic echo', () async {
    var client = testContext.httpClientFactory.newClient();
    var map = (await httpClientRead(
      client,
      httpMethodPost,
      uri,
      headers: {httpHeaderContentType: httpContentTypeJson},
      body: jsonEncode({
        'data': {
          'command': 'echo',
          'data': {'Hello': 'World'},
        },
      }),
    )).jsonToMap();
    expect(map, {
      'result': {'Hello': 'World'},
    });
    client.close();
  });
  test('basic not-found', () async {
    try {
      await callable.call<Map>({'command': 'not-found'});
      fail('should fail');
    } on HttpsError catch (e) {
      expect(e.code, HttpsErrorCode.notFound);
      expect(e.message, 'Not found');
      expect(e.details, 'command not-found');
    }
  });

  test('raw basic not-found', () async {
    var client = testContext.httpClientFactory.newClient();
    var response = (await httpClientSend(
      client,
      httpMethodPost,
      uri,
      headers: {httpHeaderContentType: httpContentTypeJson},
      body: jsonEncode({
        'data': {'command': 'not-found'},
      }),
    ));
    var body = response.body;
    var map = body.jsonToMap();
    expect(response.statusCode, 404);
    expect(map, {
      'error': {
        'details': 'command not-found',
        'message': 'Not found',
        'status': 'NOT_FOUND',
      },
    });
    client.close();
  });
  test('basic project-id', () async {
    // if failing it might just be a type error (if the result is a map)
    var result = await callable.call<String>({'command': 'project-id'});
    // var result = await callable.call<Object>({'command': 'project-id'});
    // print('result $result (${result.runtimeType})');
    expect(result.data, functionsCall.app.options.projectId);
  });
}
