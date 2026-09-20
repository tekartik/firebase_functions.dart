---
name: tekartik-firebase-functions-io-setup
description: >-
  Use when running tekartik_firebase_functions on the Dart VM (a local server,
  a docker/Cloud Run image, a vm test) with tekartik_firebase_functions_io:
  firebaseFunctionsServiceIo, firebaseFunctionsServiceHttpIo,
  firebaseFunctionsIo, the firebase_functions_io.dart import, serveHttp()/
  serve() on a real port, the legacy top level serve() with public/ file
  serving, and running the shared tekartik_firebase_functions_test suites over
  tekartik_http_io clients.
---

# tekartik_firebase_functions_io: the dart:io function server

`tekartik_firebase_functions_io` is the `dart:io` implementation of
`tekartik_firebase_functions`: it is `tekartik_firebase_functions_http` bound
to `httpServerFactoryIo`, so functions answer on a real TCP port. Everything
about registering functions, callables and firestore triggers is inherited
from the http implementation; this package only picks the server factory.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_firebase_functions_io:
      git:
        url: https://github.com/tekartik/firebase_functions.dart
        path: firebase_functions_io
  ```
  Keep the function definitions in code that depends only on
  `tekartik_firebase_functions`, and let the VM entry point (or a
  `@TestOn('vm')` test) pick this implementation.
* Single import: `package:tekartik_firebase_functions_io/firebase_functions_io.dart`.
  It re-exports `package:tekartik_firebase_functions/firebase_functions.dart`
  and `package:tekartik_firebase_functions_http/firebase_functions_http.dart`
  (`FirebaseFunctionsHttp`, `FirebaseFunctionsServiceHttp`,
  `firebaseFunctionsHttpDefaultPort`, `HttpsOptions`, `HttpsError`,
  `httpServerGetUri`, ...) and adds:
  * `firebaseFunctionsServiceIo` (alias `firebaseFunctionsServiceHttpIo`), the
    `FirebaseFunctionsServiceHttp` to use: `firebaseFunctionsServiceIo
    .functions(app)` returns a `FirebaseFunctionsHttp` cached per `FirebaseApp`;
  * `firebaseFunctionsIo`, a singleton built on a default
    `newFirebaseAppLocal()` app: convenient for a quick script, but
    `functions.params.projectId` throws on it, so prefer the service with an
    app created with `FirebaseAppOptions(projectId: ...)`;
  * the legacy top level `serve({int? port})`.
* VM only: the implementation imports `dart:io`. Do not import this library
  from web/browser code (use `tekartik_firebase_functions_http`'s memory
  implementation or `tekartik_firebase_functions_sim` there), and mark vm
  tests with `@TestOn('vm')`.
* Serving: `await functions.serveHttp(port: 0)` returns the `dart:io` backed
  `HttpServer` (real port, `httpServerGetUri(server)`, `server.port`,
  `server.close()`); `await functions.serve(port: 0)` returns an `FfServer`
  (`uri`, `close()`). Without `port` it binds `firebaseFunctionsHttpDefaultPort`
  (4999) on `InternetAddress.anyIPv4`. Register every function before serving.
* Urls are `http://localhost:<port>/<functionName>`; the rest of the path and
  the query reach the handler as `request.uri`. An unknown first segment gives
  a 404.
* The top level `serve({port})` is the legacy entry point: it always serves the
  `firebaseFunctionsIo` singleton and falls back to static files under
  `public/` (`public/index.html` for `/`) instead of a 404. Use it only for
  that file serving behaviour; `functions.serveHttp(port:)` is the normal path.
* Everything else is the http implementation's behaviour: `functions['namev1']
  = functions.https.onRequest(handler)` / `onRequestV2` / `onCall`,
  `HttpsOptions(cors: true)`, the `{"data": ...}` / `{"result": ...}` callable
  wire format, `functions.init(firestore: firestore)` before
  `functions.firestore.document(path).onWrite(...)`, and the unauthenticated
  `x-tekartik-firebase-call-uid` header for `request.context.auth?.uid` (only
  while `debugFirebaseFunctionsHttpAllowCallUidHeader` is true, i.e. asserts
  enabled: a compiled release server ignores it).
* Clients for a served function: `httpClientFactoryIo` / `httpFactoryIo`
  (`package:tekartik_http_io/http_io.dart`, a dependency) for raw http, or
  `firebaseFunctionsCallServiceHttp` from
  `tekartik_firebase_functions_call_http` with
  `FirebaseFunctionsCallOptions(region: regionBelgium, baseUri: server.uri)`
  for callables.
* Tests: reuse `FirebaseFunctionsTestContextHttp` from
  `package:tekartik_firebase_functions_http/test/firebase_functions_test_context_http.dart`
  with `httpClientFactory: httpClientFactoryIo`, then
  `setupFirebaseFunctionsTestServer`, `ffTest`, `ffFsTest` or
  `initFunctionsBasic` + `basicTestGroup` from
  `tekartik_firebase_functions_test` (dev dependency, same repo,
  `path: firebase_functions_test`). `context.serve(port: 0)` starts the server
  on a free port.
* Anti-patterns: importing this package in web code; calling the top level
  `serve()` expecting it to serve an app-scoped instance; registering functions
  after serving; keeping the default port 4999 in a test (use `port: 0`);
  trusting the uid header on a deployed server.

## Examples

### Server entry point (local run, docker or Cloud Run)

```dart
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

/// Defined in a package that only depends on tekartik_firebase_functions.
void initFunctions(FirebaseFunctions functions) {
  functions['echov1'] = functions.https.onRequestV2(
    HttpsOptions(cors: true, region: regionBelgium),
    (request) async {
      await request.response.send(requestBodyAsText(request.body));
    },
  );
}

Future<void> main(List<String> args) async {
  var port = args.isNotEmpty ? int.parse(args.first) : null;
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );
  var functions = firebaseFunctionsServiceIo.functions(app);
  initFunctions(functions);
  var server = await functions.serveHttp(port: port);
  print('serving on ${httpServerGetUri(server)}'); // .../echov1
}
```

### Call a served function with the io http client

```dart
@TestOn('vm')
library;

import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http_io/http_io.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  setUpAll(() async {
    var functions = firebaseFunctionsServiceIo.functions(
      newFirebaseAppLocal(
        options: FirebaseAppOptions(projectId: 'my-project'),
      ),
    );
    functions['echov1'] = functions.https.onRequest((request) async {
      await request.response.send(requestBodyAsText(request.body));
    });
    server = await functions.serveHttp(port: 0);
  });
  tearDownAll(() async {
    await server.close();
  });

  test('echo', () async {
    var client = httpFactoryIo.client.newClient();
    try {
      var text = await httpClientRead(
        client,
        httpMethodPost,
        httpServerGetUri(server).replace(path: 'echov1'),
        body: 'hello',
      );
      expect(text, 'hello');
    } finally {
      client.close();
    }
  });
}
```

### Shared test suite over a real port

```dart
@TestOn('vm')
library;

import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_http/test/firebase_functions_test_context_http.dart';
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http_io/http_client_io.dart';
import 'package:test/test.dart';

Future<void> main() async {
  var projectId = 'testioproject';
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: projectId),
  );
  var firestore = firestoreServiceMemory.firestore(app);
  var functions = firebaseFunctionsServiceIo.functions(app);
  functions.init(firestore: firestore);

  var context = setupFirebaseFunctionsTestServer(
    testContext: FirebaseFunctionsTestContextHttp(
      firebaseFunctions: functions,
      httpClientFactory: httpClientFactoryIo,
    ),
    firestore: firestore,
  );
  var server = await context.serve(port: 0);

  group('firebase_functions_io', () {
    ffTest(testContext: context, projectId: projectId);
    tearDownAll(() async {
      await server.close();
    });
  });
}
```

### Callable client against the io server

```dart
import 'package:tekartik_firebase_functions_call_http/functions_call_http.dart';
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );
  var functions = firebaseFunctionsServiceIo.functions(app);
  functions['pingv1'] = functions.https.onCall(
    (request) async => {'pong': request.dataAsMap['value']},
    callableOptions: HttpsCallableOptions(cors: true, region: regionBelgium),
  );
  var server = await functions.serve(port: 0);

  var functionsCall = firebaseFunctionsCallServiceHttp.functionsCall(
    app,
    options: FirebaseFunctionsCallOptions(
      region: regionBelgium,
      baseUri: server.uri,
    ),
  );
  var result = await functionsCall.callable('pingv1').call<Map>({'value': 1});
  print(result.data); // {pong: 1}
  await server.close();
}
```
