---
name: tekartik-firebase-functions-http-setup
description: >-
  Use when serving tekartik_firebase_functions over an http server or in memory
  with tekartik_firebase_functions_http: firebaseFunctionsServiceMemory,
  firebaseFunctionsMemory, FirebaseFunctionsHttp, FirebaseFunctionsHttpBase,
  FirebaseFunctionsServiceHttp, serveHttp()/serve(), FfServerHttp,
  firebaseFunctionsHttpDefaultPort, getFirebaseFunctionsHttpLocalhostUri, the
  x-tekartik-firebase-call-uid simulation header
  (firebaseFunctionsHttpHeaderUid,
  debugFirebaseFunctionsHttpAllowCallUidHeader), and the
  FirebaseFunctionsTestContextHttp / FirebaseFunctionsTestContextMemory test
  contexts.
---

# tekartik_firebase_functions_http: http/memory function server

`tekartik_firebase_functions_http` runs `tekartik_firebase_functions` on top of
a `tekartik_http` `HttpServerFactory`: one function per first url path segment.
It ships the in-memory implementation (`firebaseFunctionsServiceMemory`, no
socket, ideal for tests) and the `FirebaseFunctionsHttpBase` class that
`tekartik_firebase_functions_io` and `_sim` extend with a real server factory.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_firebase_functions_http:
      git:
        url: https://github.com/tekartik/firebase_functions.dart
        path: firebase_functions_http
  ```
  On the Dart VM depend on `tekartik_firebase_functions_io` instead (same repo,
  `path: firebase_functions_io`) and keep this one for tests.
* Imports:
  * `package:tekartik_firebase_functions_http/firebase_functions_http.dart`
    re-exports `package:tekartik_firebase_functions/firebase_functions.dart`
    (so `FirebaseApp`, `HttpsOptions`, `HttpsError`, `regionBelgium`,
    `requestBodyAsText`, `HttpServer`, `httpServerGetUri` come with it) and
    adds `FirebaseFunctionsHttp`, `FirebaseFunctionsHttpBase`,
    `FirebaseFunctionsServiceHttp`, `FirebaseFunctionsHttpDefaultMixin` and
    `firebaseFunctionsHttpDefaultPort` (4999).
  * `.../firebase_functions_memory.dart` re-exports the above and adds
    `firebaseFunctionsServiceMemory` (a `FirebaseFunctionsServiceHttp`) and
    `firebaseFunctionsMemory` (a singleton on a default local app, no
    `projectId`).
  * `.../firebase_functions_http_mixin.dart` adds `HttpsCallableFunctionHttp`,
    `firebaseFunctionsHttpHeaderUid`,
    `debugFirebaseFunctionsHttpAllowCallUidHeader` and
    `FirebaseFunctionsHttpMixinExt` (`functions.functions`, the registered
    function map).
  * `.../ff_server.dart` has `FfServerHttp(httpServer)` (`uri`, `close()`);
    `.../firebase_functions_client.dart` has
    `getFirebaseFunctionsHttpLocalhostUri({int? port})`
    (`http://localhost:4999` by default).
* Get the instance from the service, never with a constructor:
  `var functions = firebaseFunctionsServiceMemory.functions(app);` where `app`
  comes from `newFirebaseAppLocal(options: FirebaseAppOptions(projectId: ...))`
  or `newFirebaseAppMemory()` (`package:tekartik_firebase_local/firebase_local.dart`).
  The service caches one instance per app.
* Register with `functions['namev1'] = functions.https.onRequest(handler)` or
  `functions.registerFunction('namev1', ...)`; the key is the first path
  segment of the url, and the handler sees the remaining path in `request.uri`.
* Serving: `await functions.serveHttp(port: 0)` returns the raw `HttpServer`
  (`httpServerGetUri(server)` for its uri, `server.port`), `await
  functions.serve(port: 0)` wraps it in an `FfServer` (`server.uri`,
  `server.close()`). Omitting `port` uses `firebaseFunctionsHttpDefaultPort`;
  `port: 0` picks a free one. It binds `InternetAddress.anyIPv4` and prints one
  line per function. Call `serveHttp`/`serve` after registering everything.
* The memory server binds no socket: it is only reachable through
  `httpClientFactoryMemory` (`package:tekartik_http/http_memory.dart`) and its
  uri host is `_memory`. Use `tekartik_firebase_functions_io` for a real port.
* Only `HttpsFunctionHttp` values (i.e. `https.onRequest`, `onRequestV2`,
  `onCall`) are served. An unknown path falls through to `onFileRequestHttp`,
  which throws `UnsupportedError` here, so the client gets a 404 (static file
  serving needs the legacy top level `serve()` of
  `tekartik_firebase_functions_io`).
* Callables (`https.onCall`) speak the standard wire format: POST with
  `Content-Type: application/json` and a body `{"data": ...}`, answer
  `{"result": ...}`, or `{"error": {...}}` with the status code mapped from the
  `HttpsError` code. A missing/incorrect content type is answered as
  `invalid-argument`; any non-`HttpsError` exception becomes `internal`. Call
  them from Dart with `tekartik_firebase_functions_call_http`
  (`firebaseFunctionsCallServiceMemory` for the memory server).
* Caller identity is simulated: `request.context.auth?.uid` is read from the
  `firebaseFunctionsHttpHeaderUid` (`x-tekartik-firebase-call-uid`) header,
  and only while `debugFirebaseFunctionsHttpAllowCallUidHeader` is true
  (default: asserts enabled, so true under `dart test`/`dart run`, false in a
  release/AOT build). It is not authenticated: never trust it in production,
  and `context.auth?.token` is always `null` here.
* `HttpsOptions(cors: true)` adds `Access-Control-Allow-Origin: *` and mirrors
  `Access-Control-Request-Headers`; `region`/`memory`/`timeoutSeconds` are
  accepted but ignored by this implementation, and `region()`/`runWith()` are
  deprecated no-ops.
* Firestore triggers: call `functions.init(firestore: firestore)` before using
  `functions.firestore.document(path).onWrite(handler)`, else the document
  builder throws a `StateError`. The trigger is implemented with
  `firestore.doc(path).onSnapshot()`, so it only fires for writes made through
  that same `Firestore` instance, only on a fixed document path (no wildcard),
  and `EventContext.eventType`/`params`/`timestamp` throw `UnimplementedError`.
* `functions.params.projectId` throws a `StateError` unless the app was created
  with `FirebaseAppOptions(projectId: ...)`.
* Tests: `package:tekartik_firebase_functions_http/test/firebase_functions_test_context_http.dart`
  provides `FirebaseFunctionsTestContextHttp`,
  `FirebaseFunctionsTestServerContextHttp`,
  `FirebaseFunctionsTestClientContextHttp` (a `baseUrl` may contain
  `{{function}}` for a Cloud Run style url) and the matching mixins;
  `.../test/firebase_functions_test_context_memory.dart` provides
  `FirebaseFunctionsTestContextMemory` (memory client factory preset). Feed
  them to `setupFirebaseFunctionsTestServer`, `ffTest`, `ffFsTest`,
  `initFunctionsBasic`/`basicTestGroup` from
  `tekartik_firebase_functions_test` (dev dependency, same repo,
  `path: firebase_functions_test`).
* Anti-patterns: creating `FirebaseFunctionsMemory` directly; registering a
  function after `serveHttp`; using the singleton `firebaseFunctionsMemory` when
  a `projectId` is needed; reaching the memory server with a real http client;
  relying on the uid header outside tests; importing
  `package:tekartik_firebase_functions_http/src/...` (private).

## Examples

### Register and serve an http function on the memory implementation

```dart
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http_memory.dart';

Future<void> main() async {
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );
  var functions = firebaseFunctionsServiceMemory.functions(app);
  functions['echov1'] = functions.https.onRequest((request) async {
    await request.response.send(requestBodyAsText(request.body));
  });
  var server = await functions.serveHttp(port: 0);

  var client = httpClientFactoryMemory.newClient();
  var response = await client.post(
    httpServerGetUri(server).replace(path: 'echov1'),
    body: 'hello',
  );
  print('${response.statusCode} ${response.body}'); // 200 hello
  client.close();
  await server.close();
}
```

### Callable function and the simulated caller uid

```dart
import 'dart:convert';

import 'package:tekartik_firebase_functions_http/firebase_functions_http_mixin.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http.dart';
import 'package:tekartik_http/http_memory.dart';

Future<void> main() async {
  var functions = firebaseFunctionsServiceMemory.functions(
    newFirebaseAppMemory(),
  );
  functions.registerFunction(
    'whoamiv1',
    functions.https.onCall((request) async {
      var uid = request.context.auth?.uid;
      if (uid == null) {
        throw HttpsError(HttpsErrorCode.unauthenticated, 'Sign in required');
      }
      return {'uid': uid, 'data': request.dataAsMap};
    }, callableOptions: HttpsCallableOptions(cors: true)),
  );
  var server = await functions.serveHttp(port: 0);

  // Debug only: the header is not authenticated.
  debugFirebaseFunctionsHttpAllowCallUidHeader = true;
  var client = httpClientFactoryMemory.newClient();
  var text = await httpClientRead(
    client,
    httpMethodPost,
    httpServerGetUri(server).replace(path: 'whoamiv1'),
    headers: {
      httpHeaderContentType: httpContentTypeJson,
      firebaseFunctionsHttpHeaderUid: 'user1',
    },
    body: jsonEncode({
      'data': {'hi': true},
    }),
  );
  print(jsonDecode(text)); // {result: {uid: user1, data: {hi: true}}}
  client.close();
  await server.close();
}
```

### Firestore trigger on the memory implementation

```dart
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );
  var functions = firebaseFunctionsServiceMemory.functions(app);
  var firestore = firestoreServiceMemory.firestore(app);
  // Mandatory before using functions.firestore.
  functions.init(firestore: firestore);

  functions['ontestinwritev1'] = functions.firestore
      .document('test/in')
      .onWrite((change, context) async {
        await firestore.doc('test/out').set({'in': change.after.data});
      });
  var server = await functions.serve(port: 0);
  print('serving on ${server.uri}');

  await firestore.doc('test/in').set({'value': 1});
  await Future<void>.delayed(const Duration(milliseconds: 100));
  print((await firestore.doc('test/out').get()).data);
  await server.close();
}
```

### Run the shared tekartik_firebase_functions_test suite in memory

```dart
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_http/test/firebase_functions_test_context_memory.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  var projectId = 'dummyproject';
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: projectId),
  );
  var functions = firebaseFunctionsServiceMemory.functions(app);
  var firestore = firestoreServiceMemory.firestore(app);
  functions.init(firestore: firestore);

  var testContext = setupFirebaseFunctionsTestServer(
    testContext: FirebaseFunctionsTestContextMemory(
      firebaseFunctions: functions,
    ),
    firestore: firestore,
  );

  late FfServer server;
  setUpAll(() async {
    server = await testContext.serve();
    testContext.functionsCall = firebaseFunctionsCallServiceMemory
        .functionsCall(
          app,
          options: FirebaseFunctionsCallOptions(
            region: regionBelgium,
            baseUri: server.uri,
          ),
        );
  });
  ffTest(testContext: testContext, projectId: projectId);
  tearDownAll(() async {
    await server.close();
  });
}
```
