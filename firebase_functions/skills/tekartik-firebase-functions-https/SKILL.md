---
name: tekartik-firebase-functions-https
description: >-
  Use when writing Firebase Cloud Functions in Dart with
  tekartik_firebase_functions: registering HTTPS request functions
  (FirebaseFunctions, HttpsFunctions.onRequest, ExpressHttpRequest/Response),
  callable functions (onCall, CallRequest, HttpsError), GlobalOptions and
  regions, serving them locally with serve()/FfServer on the io, memory or sim
  implementation, and calling them from tests through
  tekartik_firebase_functions_call.
---

# tekartik_firebase_functions HTTPS functions

Abstraction to write Firebase Cloud Functions in Dart: one `FirebaseFunctions`
per `FirebaseApp`, from a `FirebaseFunctionsService`. Implementations: io
(`firebaseFunctionsServiceIo`, Dart server / Cloud Run), http memory
(`firebaseFunctionsServiceMemory`), sim (`firebaseFunctionsServiceSim`), node
(`firebaseFunctionsNode`) and admin sdk (`firebaseFunctionsServiceAdminSdk`).

## Guidelines

* Import `package:tekartik_firebase_functions/firebase_functions.dart`. It
  re-exports `package:tekartik_firebase/firebase.dart` (`FirebaseApp`,
  `FirebaseAppOptions`), `DocumentSnapshot`, the firestore and scheduler
  libraries and `package:tekartik_http/http_server.dart` (`HttpHeaders`,
  `HttpServer`, `httpServerGetUri`). Constants such as `httpHeaderContentType`,
  `httpContentTypeJson` or `httpStatusCodeNotFound` come from
  `package:tekartik_http/http.dart`.
* Keep the function definitions in a package depending only on
  `tekartik_firebase_functions`, as `initFunctions(FirebaseFunctions functions)`;
  the entry point picks the implementation (`firebaseFunctionsServiceIo
  .functions(app)`, `firebaseFunctionsServiceMemory.functions(app)` in tests).
* Register with `functions['name'] = ...` or `functions.registerFunction(...)`.
  The key is the deployed name and URL path segment: lowercase, no underscore,
  versioned (`'echov1'`) so a breaking change is a new function.
* Raw handler: `functions.https.onRequest(handler, httpsOptions:
  HttpsOptions(cors: true, region: regionBelgium))` (`onRequestV2(options,
  handler)` takes the options first). A `RequestHandler` must finish the
  response: `await request.response.send(body)` (`String`, bytes, `Map`/`List`
  JSON encoded) or `write`/`writeln`/`add` then `close()`. Set `statusCode`
  and headers (`response.headers.set(httpHeaderContentType,
  httpContentTypeJson)`) before `send`; on node only `send` terminates.
* Read `request.method`, `request.uri` (path relative to the function, query),
  `request.headers` and the body with `request.bodyAsMap`, `bodyAsMapOrNull`,
  `bodyAsString` (`ExpressHttpRequestExt`) or `requestBodyAsJsonObject(body)` /
  `requestBodyAsText(body)`; `request.body` is raw (`String`, bytes or `Map`
  depending on the platform). `requestedUri` and `bodyAsText` are deprecated.
* Callable: `functions.https.onCall(handler, callableOptions:
  HttpsCallableOptions(cors: true, region: regionBelgium, enforceAppCheck:
  false))`. A `CallHandler` returns a JSON-encodable value sent as
  `{"result": ...}`. Read the input with `request.dataAsMap`, `dataAsText` or
  `data`, the caller with `request.context.auth?.uid` (`null` when anonymous).
* Throw `HttpsError(HttpsErrorCode.notFound, 'Not found', details)` for
  client-visible errors; any other exception becomes `HttpsErrorCode.internal`.
  Do not return error maps from a callable. Codes are strings
  (`'not-found'`, `'permission-denied'`, `'unauthenticated'`, ...).
* `HttpsOptions`/`HttpsCallableOptions` extend `GlobalOptions` (`region` or
  `regions`, `memory` as `'256MiB'`, `timeoutSeconds`, `concurrency`,
  `maxInstances`). Set defaults once with `functions.globalOptions =
  GlobalOptions(region: regionBelgium)`; `region()`, `runWith()` and
  `RuntimeOptions` are deprecated v1 APIs. Prefer `regionBelgium`
  (europe-west1); `regionUsCentral1` is the emulator default.
  `functions.params.projectId` is the project id (throws on a local app
  without `FirebaseAppOptions.projectId`); `functions.app` the `FirebaseApp`.
* Local serving: `await functions.serve(port: 0)` returns an `FfServer`
  (`uri`, `close()`; import `package:tekartik_firebase_functions/ff_server.dart`)
  answering at `${server.uri}/<name>`. On `FirebaseFunctionsHttp` (io, memory,
  sim) `serveHttp(port:)` returns the raw `HttpServer`; the default port is
  `firebaseFunctionsHttpDefaultPort` (4999). Only https functions are served.
* Call from Dart with `tekartik_firebase_functions_call`:
  `FirebaseFunctionsCall.callable(name)` or `callableFromUri(uri)`, then
  `callable.call<Map>(data)` and `result.data`; failures arrive as
  `HttpsError`. `firebaseFunctionsCallServiceHttp`
  (`package:tekartik_firebase_functions_call_http/functions_call_http.dart`) and
  `firebaseFunctionsCallServiceMemory` (`functions_call_memory.dart`) need
  `FirebaseFunctionsCallOptions(region: regionBelgium, baseUri: server.uri)`
  for `callable(name)`. On Flutter use the native callable plugin.
* Wire format (http implementation): POST JSON `{"data": ...}` with
  `Content-Type: application/json` (else `invalid-argument`); answer
  `{"result": ...}` or `{"error": {"status": "NOT_FOUND", "message", "details"}}`
  with the mapped status code. `package:tekartik_firebase_functions/utils.dart`
  has `httpsErrorCodeToStatusCode`, `HttpsErrorHttpExt.toHttpJson()`,
  `httpsErrorFromJsonMap`, `anyExceptionToHttpsError`, `onCallHandlerAsRequestHandler`.
* Simulated caller on an http/memory server: the header
  `firebaseFunctionsHttpHeaderUid` (`x-tekartik-firebase-call-uid`, in
  `package:tekartik_firebase_functions_http/firebase_functions_http_mixin.dart`)
  is honoured only while `debugFirebaseFunctionsHttpAllowCallUidHeader` is
  true (default with asserts on); the http callable client sends it from the
  app's current `FirebaseAuth` user. Never rely on it in production.
* Test helpers in `tekartik_firebase_functions_test`: `echoHandler`,
  `initTestFunctions`, `setupFirebaseFunctionsTestServer`, `ffTest`,
  `basicTestGroup`, `initFunctionsBasic`. For mocks mix in
  `FirebaseFunctionsDefaultMixin`, `HttpsFunctionsDefaultMixin`,
  `CallRequestMixin`, `CallContextMixin` or `CallContextAuthMixin`.

## Examples

### Shared function definitions

```dart
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_http/http.dart';

const functionInfo = 'infov1';
const functionApi = 'apiv1';

/// Registers the app functions on any implementation (io, node, admin sdk).
void initFunctions(FirebaseFunctions functions) {
  functions.globalOptions = GlobalOptions(region: regionBelgium);
  functions[functionInfo] = functions.https.onRequest(
    (request) => infoHandler(functions, request),
    httpsOptions: HttpsOptions(cors: true, timeoutSeconds: 60),
  );
  functions[functionApi] = functions.https.onCall(
    apiHandler,
    callableOptions: HttpsCallableOptions(cors: true, enforceAppCheck: false),
  );
}

Future<void> infoHandler(
  FirebaseFunctions functions,
  ExpressHttpRequest request,
) async {
  var response = request.response;
  response.headers.set(httpHeaderContentType, httpContentTypeJson);
  await response.send({
    'method': request.method,
    'body': request.bodyAsMapOrNull,
    'projectId': functions.params.projectId,
  });
}
```

### Callable handler with auth and errors

```dart
import 'package:tekartik_firebase_functions/firebase_functions.dart';

Future<Object?> apiHandler(CallRequest request) async {
  var data = request.dataAsMap;
  var command = data['command'];
  if (command == 'ping') {
    return 'pong';
  }
  var uid = request.context.auth?.uid;
  if (uid == null) {
    throw HttpsError(HttpsErrorCode.unauthenticated, 'Sign in required');
  }
  if (command == 'echo') {
    return {'uid': uid, 'data': data['data']};
  }
  throw HttpsError(HttpsErrorCode.invalidArgument, 'Unknown command', data);
}
```

### Test with the memory implementation and the callable client

```dart
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';
// plus the file defining initFunctions and functionApi.
void main() {
  late FfServer server;
  late FirebaseFunctionsCallable callable;
  setUpAll(() async {
    var app = newFirebaseAppLocal(
      options: FirebaseAppOptions(projectId: 'testproject'),
    );
    var functions = firebaseFunctionsServiceMemory.functions(app);
    initFunctions(functions);
    server = await functions.serve(port: 0);
    var functionsCall = firebaseFunctionsCallServiceMemory.functionsCall(
      app,
      options: FirebaseFunctionsCallOptions(
        region: regionBelgium,
        baseUri: server.uri,
      ),
    );
    callable = functionsCall.callable(functionApi);
  });
  tearDownAll(() => server.close());
  test('callable', () async {
    expect((await callable.call<String>({'command': 'ping'})).data, 'pong');
    try {
      await callable.call<Map>({'command': 'echo'});
      fail('should fail');
    } on HttpsError catch (e) {
      expect(e.code, HttpsErrorCode.unauthenticated);
    }
  });
}
```
