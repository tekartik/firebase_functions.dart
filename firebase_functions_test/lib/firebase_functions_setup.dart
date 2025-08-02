import 'dart:typed_data';

import 'package:tekartik_firebase_functions/utils.dart';
import 'package:tekartik_firebase_functions_test/src/import.dart';

import 'constants.dart';
import 'firebase_functions_test.dart';
export 'package:tekartik_firebase_functions/firebase_functions.dart';

void echoBytesHandler(ExpressHttpRequest request) {
  var body = request.body;
  //devPrint('echoBytes ${body?.runtimeType}: ${body}');
  request.response.headers.contentType = request.headers.contentType;
  request.response.send(body as Uint8List?);
}

void echoHandler(ExpressHttpRequest request) {
  // print("request.url ${request.uri}");
  //request.response.write(requestBodyAsText(request.body));
  //request.response.close();
  request.response.send(requestBodyAsText(request.body));
}

void echoQueryHandler(ExpressHttpRequest request) {
  // print("request.url ${request.uri} ${request.uri.queryParameters}");
  request.response.send(request.uri.query);
}

void echoFragmentHandler(ExpressHttpRequest request) {
  // print("request.url ${request.uri} ${request.uri.fragment}");
  request.response.send(request.uri.fragment);
}

void echoInfoHandler(ExpressHttpRequest request) {
  //request.response.headers.contentType = request.headers.contentType;
  request.response.headers.set(httpHeaderContentType, httpContentTypeJson);
  request.response.send({
    'method': request.method,
    'uri': request.uri.toString(),
  });
}

void infoHandler(FirebaseFunctions functions, ExpressHttpRequest request) {
  //request.response.headers.contentType = request.headers.contentType;
  request.response.headers.set(httpHeaderContentType, httpContentTypeJson);
  request.response.send({'projectId': functions.params.projectId});
}

void echoHeadersHandler(ExpressHttpRequest request) {
  // print("request.url ${request.uri} ${request.uri.fragment}");
  var sb = StringBuffer();
  request.headers.forEach((name, values) {
    sb.writeln('name: ${values.join(', ')}');
  });
  request.response.send(sb.toString());
}

Future<Object?> callHandler(CallRequest request) async {
  await Future<void>.delayed(Duration(milliseconds: 100));
  //devPrint('request data ${request.text}');
  try {
    return {'v': 1, 'uid': request.context.auth?.uid, 'data': request.data};
  } catch (error) {
    try {
      return {'v': 2, 'data': request.data, 'error': '$error'};
    } catch (error) {
      return {'v': 3, 'error': '$error'};
    }
  }
}

FutureOr<Object?> _testFunctionHandler(FunctionTestInputData input) {
  switch (input.command) {
    case testCommandData:
      return input.data;
    case testCommandNotFound:
      throw HttpsError(
        HttpsErrorCode.notFound,
        'Not found',
        'command $testCommandNotFound',
      );
    case testCommandThrow:
      throw Exception('throw unsupported to throw on purpose');
  }
  return UnsupportedError('unsupported command ${input.command}');
}

Map<String, Object?> _outputData(Object? data) {
  return FunctionTestOutputData(data: data).toMap();
}

/// Test
Future<Object?> testCallableFunctionHandler(CallRequest request) async {
  var input = FunctionTestInputData.fromMap(
    request.dataAsMap,
    userId: request.context.auth?.uid,
  );
  switch (input.command) {
    case testCommandRaw:
      return input.data;
  }
  var result = await _testFunctionHandler(input);
  return _outputData(result);
}

FutureOr<void> testHttpFunctionHandler(ExpressHttpRequest request) async {
  var response = request.response;
  var input = FunctionTestInputData.fromMap(request.bodyAsMap);
  switch (input.command) {
    case testCommandRaw:
      return request.response.send(null);
  }
  try {
    var result = await _testFunctionHandler(input);
    return response.send(_outputData(result));
  } on HttpsError catch (e) {
    var statusCode = httpsErrorCodeToStatusCode(e.code);
    response.statusCode = statusCode;
    await response.send(jsonEncode({'https_error': '$e'}));
  } catch (e) {
    response.statusCode = httpStatusCodeInternalServerError;
    await response.send(jsonEncode({'error': '$e'}));
    //return request.response.statusCode = httpStatusCodeInternalServerError;
  }
}

class TestContext {
  String? baseUrl;
}

T setup<T extends FirebaseFunctionsTestServerContext>({
  required T testContext,
  FirebaseFunctions? firebaseFunctions,
  TestContext? context,
  String? testRedirectUrl,
}) {
  firebaseFunctions ??= testContext.firebaseFunctions;
  initTestFunctions(
    firebaseFunctions: firebaseFunctions,
    testRedirectUrl: testRedirectUrl,
  );

  return testContext;
}

void initTestFunctions({
  required FirebaseFunctions firebaseFunctions,

  String? testRedirectUrl,
}) {
  /// Not working not tested yet
  void redirectFragmentHandler(ExpressHttpRequest request) {
    // print("request.url ${request.uri} ${request.uri.fragment}");
    request.response.redirect(Uri.parse(testRedirectUrl!));
  }

  firebaseFunctions['echo'] = firebaseFunctions.https.onRequestV2(
    HttpsOptions(cors: true, region: regionBelgium),
    echoHandler,
  );

  firebaseFunctions['redirect'] = firebaseFunctions.https.onRequestV2(
    HttpsOptions(cors: true, region: regionBelgium),
    redirectFragmentHandler,
  );
  firebaseFunctions['echoquery'] = firebaseFunctions.https.onRequestV2(
    HttpsOptions(cors: true, region: regionBelgium),
    echoQueryHandler,
  );
  firebaseFunctions['echobytes'] = firebaseFunctions.https.onRequestV2(
    HttpsOptions(cors: true, region: regionBelgium),
    echoBytesHandler,
  );
  firebaseFunctions['echofragment'] = firebaseFunctions.https.onRequestV2(
    HttpsOptions(cors: true, region: regionBelgium),
    echoFragmentHandler,
  );
  firebaseFunctions['echoheaders'] = firebaseFunctions.https.onRequestV2(
    HttpsOptions(cors: true, region: regionBelgium),
    echoHeadersHandler,
  );
  firebaseFunctions['echoinfo'] = firebaseFunctions.https.onRequestV2(
    HttpsOptions(cors: true, region: regionBelgium),
    echoInfoHandler,
  );
  firebaseFunctions['ffinfo'] = firebaseFunctions.https.onRequest(
    (request) => infoHandler(firebaseFunctions, request),
    httpsOptions: HttpsOptions(cors: true, region: regionBelgium),
  );

  firebaseFunctions[functionCallName] = firebaseFunctions.https.onCall(
    callHandler,
    callableOptions: HttpsCallableOptions(
      cors: true,
      region: regionBelgium,
      enforceAppCheck: false,
    ),
  );

  firebaseFunctions[functionCallAppCheckName] = firebaseFunctions.https.onCall(
    callHandler,
    callableOptions: HttpsCallableOptions(
      cors: true,
      region: regionBelgium,
      enforceAppCheck: true,
    ),
  );

  firebaseFunctions[callableFunctionTestName] = firebaseFunctions.https.onCall(
    testCallableFunctionHandler,
    callableOptions: HttpsCallableOptions(
      cors: true,
      region: regionBelgium,
      enforceAppCheck: false,
    ),
  );
  firebaseFunctions[httpFunctionTestName] = firebaseFunctions.https.onRequest(
    testHttpFunctionHandler,
    httpsOptions: HttpsOptions(cors: true, region: regionBelgium),
  );
}

var testFunctionNames = [
  'echo',
  'redirect',
  'echoquery',
  'echobytes',
  'echofragment',
  'echoheaders',
  'echoinfo',
  'ffinfo',
  functionCallName,
  functionCallAppCheckName,
  callableFunctionTestName,
  httpFunctionTestName,
];
