import 'dart:typed_data';

import 'package:cv/cv_json.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_firebase_functions_test/src/firebase_functions_call_test.dart';
import 'package:tekartik_firebase_functions_test/src/firebase_functions_test_context.dart';
import 'package:tekartik_firebase_functions_test/src/trigger_fs_functions.dart';
// ignore: depend_on_referenced_packages
import 'package:test/test.dart';

import 'constants.dart';
import 'import.dart';

export 'package:tekartik_firebase_functions/firebase_functions.dart';
export 'package:tekartik_http/http_utils.dart';

export 'firebase_functions_test_context.dart';

class FunctionTestOutputData {
  final Object? data;

  FunctionTestOutputData({this.data});

  Map<String, Object?> toMap() {
    return {'data': data};
  }

  factory FunctionTestOutputData.fromMap(Map map) {
    return FunctionTestOutputData(data: map['data']);
  }

  @override
  String toString() => toMap().toString();
}

class FunctionTestInputData {
  final String? userId;
  final String command;
  final Object? data;
  final FirebaseApp? firebaseApp;

  FunctionTestInputData({
    this.userId,
    required this.command,
    this.data,
    this.firebaseApp,
  });

  Map<String, Object?> toMap() {
    return {
      'userId': userId,
      'command': command,
      'data': data,
      if (firebaseApp != null) 'projectId': firebaseApp!.options.projectId,
    };
  }

  @override
  String toString() => toMap().toString();

  factory FunctionTestInputData.fromMap(
    Map map, {
    String? userId,
    FirebaseApp? firebaseApp,
  }) {
    return FunctionTestInputData(
      userId: userId ?? map['userId'] as String?,
      command: map['command'] as String,
      data: map['data'],
      firebaseApp: firebaseApp,
    );
  }
}

class _FirebaseFunctionsCallTestClientContext
    implements FirebaseFunctionsCallTestClientContext {
  final FirebaseFunctionsTestClientContext testClientContext;

  _FirebaseFunctionsCallTestClientContext(this.testClientContext);

  @override
  FirebaseFunctionsCall get functionsCall => testClientContext.functionsCall!;
}

void ffTest({
  required FirebaseFunctionsTestClientContext testContext,
  HttpClientFactory? httpClientFactory,
  String? baseUrl,
  String? projectId,
}) {
  late HttpClientFactory clientFactory;
  setUpAll(() async {
    clientFactory = httpClientFactory ??= testContext.httpClientFactory;
  });
  test('post', () async {
    var client = httpClientFactory!.newClient();
    var response = await client.post(
      Uri.parse(testContext.url('echo')),
      body: 'hello',
    );
    expect(response.statusCode, 200);
    expect(response.contentLength, greaterThan(0));
    expect(response.body, equals('hello'));

    client.close();
  });

  test('echoBytes binary', () async {
    var client = httpClientFactory!.newClient();
    var response = await client.post(
      Uri.parse(testContext.url('echobytes')),
      body: Uint8List.fromList([1, 2, 3]),

      /// Needed for node
      headers: {httpHeaderContentType: httpContentTypeBytes},
    );
    expect(response.statusCode, 200);
    expect(response.contentLength, greaterThan(0));
    expect(response.bodyBytes, [1, 2, 3]);
    // Not working memory/http expect(response.headers[httpHeaderContentType], httpContentTypeBytes);
    client.close();
  });

  test('echoBytes test', () async {
    var content = 'éàö';
    var client = httpClientFactory!.newClient();
    var response = await client.post(
      Uri.parse(testContext.url('echobytes')),
      body: content,

      /// Needed for node
      headers: {httpHeaderContentType: httpContentTypeText},
    );
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
    var response = await client.post(
      Uri.parse(testContext.url('echobytes')),
      body: jsonEncode(map),

      /// Needed for node
      headers: {httpHeaderContentType: httpContentTypeJson},
    );
    expect(response.statusCode, 200);
    expect(response.contentLength, greaterThan(0));
    expect(jsonDecode(utf8.decode(response.bodyBytes)), map);
    expect(jsonDecode(response.body), map);
    // Not working memory/http expect(response.headers[httpHeaderContentType], httpContentTypeJson);

    client.close();
  });

  test('queryParams', () async {
    var client = httpClientFactory!.newClient();
    var response = await client.get(
      Uri.parse(testContext.url('echoquery?dev&param=value')),
    );
    expect(response.statusCode, 200);
    expect(response.body, 'dev&param=value');

    client.close();
  });

  test('fragment', () async {
    var client = httpClientFactory!.newClient();
    var response = await client.get(
      Uri.parse(testContext.url('echofragment#some_fragment')),
    );
    expect(response.statusCode, 200);
    // Server has no fragment
    expect(response.body, '');
    client.close();
  });

  test('info', () async {
    var client = httpClientFactory!.newClient();
    var response = await client.get(
      Uri.parse(testContext.url('echoinfo?param#fragment')),
    );
    expect(response.statusCode, 200);
    // Server has no fragment
    var decoded = jsonDecode(response.body);
    try {
      expect(decoded, {'method': 'GET', 'uri': '?param#'});
    } catch (e) {
      // On node we have a leading /
      expect(decoded, {'method': 'GET', 'uri': '/?param'});
    }
    response = await client.post(
      Uri.parse(testContext.url('echoinfo/sub1/sub2?param#fragment')),
    );
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

  test('ffinfo', () async {
    var client = clientFactory.newClient();
    var map =
        jsonDecode(await client.read(Uri.parse(testContext.url('ffinfo'))))
            as Map;
    if (projectId != null) {
      expect(map['projectId'], projectId);
    }
    client.close();
  });

  test('headers', () async {
    var client = httpClientFactory!.newClient();
    var response = await client.get(
      Uri.parse(testContext.url('echoheaders')),
      headers: {'x-test1': 'value1'},
    );
    expect(response.statusCode, 200);
    // Server has no fragment
    // For http io we might have
    //              'name: Dart/3.4 (dart:io)\n'
    //             'name: value1\n'
    //             'name: gzip\n'
    //             'name: localhost:44295\n'
    //             ''
    expect(
      response.body,
      contains('name: value1'),
    ); // don't care about line feed
    client.close();
  });

  test('redirect', () async {
    var client = httpClientFactory!.newClient();
    var response = await client.post(
      Uri.parse(testContext.url('redirect')),
      body: 'hello',
    );
    expect(response.statusCode, 302);
    // no echo
    expect(response.body, '');
    expect(response.headers['location'], '$baseUrl/echo');
    client.close();
  }, skip: true);

  group('testFunction', () {
    // functions call will change later, but we know it supports it
    var functionsCall = testContext.functionsCall;
    if (functionsCall != null) {
      ffCallTestGroup(
        testContext: _FirebaseFunctionsCallTestClientContext(testContext),
      );
    }

    group('http $httpFunctionTestName', () {
      late HttpFunctionTestClient client;

      setUpAll(() async {
        var httpClient = clientFactory.newClient();
        var uri = Uri.parse(testContext.url(httpFunctionTestName));
        client = HttpFunctionTestClient(httpClient, uri);
      });

      test('data', () async {
        await client.testData();
      });
      test('throw', () async {
        try {
          await client.sendThrow();
        } on HttpClientException catch (e) {
          expect(e.statusCode, httpStatusCodeInternalServerError);
        }
      });
      test('not-found', () async {
        try {
          await client.sendNotFound();
        } on HttpClientException catch (e) {
          expect(e.statusCode, httpStatusCodeNotFound);
        }
      });
      test('raw', () async {
        var result = await client.sendRaw(null);
        expect(result, isA<Uint8List>());
        expect(result, isEmpty);
      });
      tearDownAll(() async {
        await client.close();
      });
    });
  });
}

void ffFsTest({
  required FirebaseFunctionsTestClientContext testContext,
  HttpClientFactory? httpClientFactory,
  String? baseUrl,
  String? projectId,

  /// If testing firestore triggers
  Firestore? firestore,
  Version? version,
}) {
  late HttpClientFactory clientFactory;
  setUpAll(() async {
    clientFactory = httpClientFactory ??= testContext.httpClientFactory;
  });

  group('fs and trigger', () {
    late Client client;

    int? getInValue(String body) {
      var map = body.cv<CvMapModel>();
      return map.getKeyPathValue<int?>(['in', 'value']);
    }

    Version? getVersion(String body) {
      var map = body.cv<CvMapModel>();
      var versionText = map.getKeyPathValue<String?>(['version']);
      if (versionText == null) {
        return null;
      }
      return Version.parse(versionText);
    }

    Version? getTriggerVersion(String body) {
      var map = body.cv<CvMapModel>();
      var versionText = map.getKeyPathValue<String?>(['out', 'triggerVersion']);
      if (versionText == null) {
        return null;
      }
      return Version.parse(versionText);
    }

    int? getOutValue(String body) {
      var map = body.cv<CvMapModel>();
      return map.getKeyPathValue<int?>(['out', 'value']);
    }

    setUpAll(() async {
      var httpClient = clientFactory.newClient();
      var uri = Uri.parse(testContext.url(httpFunctionTestName));
      client = HttpFunctionTestClient(httpClient, uri).client;
    });
    tearDownAll(() async {
      client.close();
    });
    if (firestore != null) {
      test('trigger and version', () async {
        var uriGet = Uri.parse(testContext.url(functionGetOutTrigger));
        var body = await client.read(uriGet);
        var inValueInitial = getInValue(body);
        var versionInitial = getVersion(body);
        print(
          'inValue: $inValueInitial (will be bumped twice), version: $versionInitial',
        );
        if (version != null) {
          expect(versionInitial, greaterThanOrEqualTo(version));
        }

        // print('Initial body: $body');
        var uriSet = Uri.parse(testContext.url(functionSetInTrigger));
        print('url: $uriSet');
        var response = await client.get(uriSet);
        expect(response.statusCode, 200);
        expect(response.contentLength, greaterThan(0));
        body = response.body;
        var inValue1 = getInValue(body)!;
        expect(inValue1, isNotNull);
        // var outValue1 = getOutValue(body);
        print('inValue: $inValue1');
        // print('outValue1: $outValue1');

        body = await client.read(uriSet);

        var inValue2 = getInValue(body);
        // var outValue2 = getOutValue(body);
        // print('inValue2: $inValue2');
        expect(inValue2, greaterThan(inValue1));
        // print('outValue2: $outValue2');
        var sw = Stopwatch()..start();

        while (sw.elapsedMilliseconds < 30000) {
          body = await client.read(uriGet);
          // var inValue = getInValue(body);
          var outValue = getOutValue(body);
          // print('inValue: $inValue');
          // print('outValue: $outValue');
          if (outValue != null && outValue >= inValue1) {
            var triggerVersion = getTriggerVersion(body)!;
            print('outValue: $outValue, triggerVersion: $triggerVersion');

            if (version != null) {
              expect(triggerVersion, greaterThanOrEqualTo(version));
            } else {
              print('version not checked');
            }
            return;
          }
          await sleep(100);
        }
      }, timeout: Timeout(Duration(minutes: 2)));
    }
  });
}

class HttpFunctionTestClient extends FunctionTestClient {
  final Client client;
  final Uri uri;

  HttpFunctionTestClient(this.client, this.uri);

  @override
  Future<FunctionTestOutputData> send(FunctionTestInputData data) async {
    var response = await httpClientSend(
      client,
      httpMethodPost,
      uri,
      body: jsonEncode(data.toMap()),
      throwOnFailure: true,
    );
    return FunctionTestOutputData.fromMap(response.bodyAsMap);
  }

  @override
  Future<Object?> rawSend(FunctionTestInputData data) async {
    var response = await httpClientSend(
      client,
      httpMethodPost,
      uri,
      body: jsonEncode(data.toMap()),
      throwOnFailure: true,
    );
    return response.bodyBytes;
  }

  @override
  Future<void> close() async {
    client.close();
  }
}

abstract class FunctionTestClient {
  Future<FunctionTestOutputData> send(FunctionTestInputData data);

  Future<Object?> rawSend(FunctionTestInputData data);

  Future<Object?> sendRaw(Object? raw) async {
    return await _sendRaw<Object?>(raw);
  }

  Future<T> _sendRaw<T>(Object? raw) async {
    var data = FunctionTestInputData(command: testCommandRaw, data: raw);
    return (await rawSend(data)) as T;
  }

  Future<void> sendThrow() async {
    var data = FunctionTestInputData(command: testCommandThrow, data: null);
    await send(data);
  }

  Future<void> sendNotFound() async {
    var data = FunctionTestInputData(command: testCommandNotFound, data: null);
    await send(data);
  }

  Future<String?> getUserLoggedIn() async {
    var data = FunctionTestInputData(command: testCommandUserId, data: null);
    var result = await send(data);
    return result.data?.toString();
  }

  Future<String?> getProjectId() async {
    var data = FunctionTestInputData(command: testCommandProjectId, data: null);
    var result = await send(data);
    return result.data?.toString();
  }

  Future<void> testData() async {
    for (var data in [
      null,
      1,
      'test',
      [1, 2],
      {'test': 1},
      true,
    ]) {
      try {
        var input = FunctionTestInputData(command: testCommandData, data: data);
        // devPrint('input $input');
        var output = await send(input);
        // devPrint('input $output');

        expect(output.data, data);
      } catch (e) {
        print('Error for $data');
        print('Error: $e');
        rethrow;
      }
    }
  }

  Future<void> close() async {}
}
