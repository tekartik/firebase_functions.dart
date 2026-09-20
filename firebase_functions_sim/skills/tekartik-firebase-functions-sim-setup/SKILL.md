---
name: tekartik-firebase-functions-sim-setup
description: >-
  Use when running tekartik_firebase_functions in a local simulator/dev server
  with tekartik_firebase_functions_sim: firebaseFunctionsServiceSim, the
  firebase_functions_sim.dart import (which re-exports the io and http
  libraries), serveHttp on the sim http port, and plugging the functions
  service into a firebaseSimServe websocket server through
  FirebaseFunctionsCallSimPlugin so sim clients can call them.
---

# tekartik_firebase_functions_sim: functions in the local simulator

`tekartik_firebase_functions_sim` is the implementation flavour used by the
Tekartik firebase simulator: a local dev server that hosts the Cloud Functions
of a project so that sim/browser clients can call them. Today
`firebaseFunctionsServiceSim` is exactly the `dart:io` service, so it behaves
like `tekartik_firebase_functions_io` with a sim-oriented import.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_firebase_functions_sim:
      git:
        url: https://github.com/tekartik/firebase_functions.dart
        path: firebase_functions_sim
  ```
  Add `tekartik_firebase_functions_call_sim` (same repo,
  `path: functions_call_sim`) and `tekartik_firebase_sim`
  (`https://github.com/tekartik/firebase.dart`, `path: firebase_sim`) when the
  sim server must expose the functions to sim clients.
* Single import: `package:tekartik_firebase_functions_sim/firebase_functions_sim.dart`.
  It re-exports `package:tekartik_firebase_functions/firebase_functions.dart`,
  `package:tekartik_firebase_functions_http/firebase_functions_http.dart` and
  `package:tekartik_firebase_functions_io/firebase_functions_io.dart`, so
  `FirebaseFunctionsHttp`, `HttpsOptions`, `HttpsError`, `regionBelgium`,
  `httpServerGetUri`, `firebaseFunctionsServiceIo`, `firebaseFunctionsIo` and
  `firebaseFunctionsHttpDefaultPort` all come with it, plus the one symbol this
  package owns: `firebaseFunctionsServiceSim`.
* `firebaseFunctionsServiceSim` is a `FirebaseFunctionsServiceHttp` and is
  currently an alias of `firebaseFunctionsServiceIo`. Use it anyway in sim/dev
  server code: it is the name that will keep pointing at the simulator
  implementation. `lib/firebase_functions_sim_server.dart` is an empty
  placeholder, do not import it.
* VM only (it pulls `dart:io` through the io implementation). Sim *clients*
  (browser, Flutter) use `tekartik_firebase_functions_call_sim` instead, which
  needs no `dart:io`.
* Usage is the http/io one: `var functions = firebaseFunctionsServiceSim
  .functions(app);` (one instance per `FirebaseApp`, from
  `FirebaseLocal().initializeApp()` or `newFirebaseAppLocal(options:
  FirebaseAppOptions(projectId: ...))`), then
  `functions['namev1'] = functions.https.onRequestV2(HttpsOptions(cors: true),
  handler)` / `onRequest` / `onCall`, and
  `await functions.serveHttp(port: port)` (raw `HttpServer`) or
  `await functions.serve(port: port)` (`FfServer`). Default port:
  `firebaseFunctionsHttpDefaultPort` (4999), `port: 0` for a free one.
  Functions answer at `<serverUri>/<functionName>`.
* `functions.init(firestore: firestore)` is required before
  `functions.firestore.document(path).onWrite(...)`, and
  `functions.params.projectId` needs an app created with a `projectId`.
* Sim server wiring (`tekartik_firebase_functions_call_sim`): pass a
  `FirebaseFunctionsCallSimPlugin(firebaseFunctionsService:
  firebaseFunctionsServiceSim, options: FirebaseFunctionsCallSimPluginOptions(
  initFunction: ..., initFunctions: {projectId: ...}, httpPort: ...))` to
  `firebaseSimServe(FirebaseLocal(), port: ..., plugins: [...])`
  (`package:tekartik_firebase_sim/firebase_sim_server.dart`). The plugin calls
  the init function once per app, then serves the functions over http itself;
  `simServer.initializeAppAsync()` starts it eagerly and
  `simServer.httpFunctionsUri` (extension in
  `package:tekartik_firebase_functions_call_sim/functions_call_sim_server.dart`)
  gives the http base uri. Do not also call `serveHttp` yourself in that setup.
* The unauthenticated `x-tekartik-firebase-call-uid` header
  (`firebaseFunctionsHttpHeaderUid`) provides `request.context.auth?.uid` on
  http calls while `debugFirebaseFunctionsHttpAllowCallUidHeader` is true
  (asserts enabled); a sim server compiled in release ignores it.
* Tests: `FirebaseFunctionsTestContextHttp`
  (`package:tekartik_firebase_functions_http/test/firebase_functions_test_context_http.dart`)
  with `httpClientFactory: httpClientFactoryIo`, then
  `setupFirebaseFunctionsTestServer`, `ffTest`, `ffFsTest` from
  `tekartik_firebase_functions_test` (dev dependency, same repo,
  `path: firebase_functions_test`); `ffFsTest` also wants
  `version: packageVersion`.
* Anti-patterns: importing this package from web/browser code; importing
  `firebase_functions_sim_server.dart`; serving the functions twice (plugin +
  manual `serveHttp`); hardcoding 4999 in tests instead of `port: 0`.

## Examples

### Local sim http server

```dart
import 'package:tekartik_firebase_functions_sim/firebase_functions_sim.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main(List<String> args) async {
  var port = args.isNotEmpty ? int.parse(args.first) : null;
  var app = FirebaseLocal().initializeApp(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );
  var functions = firebaseFunctionsServiceSim.functions(app);
  functions['echov1'] = functions.https.onRequestV2(
    HttpsOptions(cors: true, region: regionBelgium),
    (request) async {
      await request.response.send(requestBodyAsText(request.body));
    },
  );
  var server = await functions.serveHttp(port: port);
  print('functions on ${httpServerGetUri(server)}'); // .../echov1
}
```

### Expose the functions through the firebase sim server

```dart
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim_server.dart';
import 'package:tekartik_firebase_functions_sim/firebase_functions_sim.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

/// Called once per app by the plugin.
void initFunctions({required FirebaseApp firebaseApp}) {
  var functions = firebaseFunctionsServiceSim.functions(firebaseApp);
  functions['pingv1'] = functions.https.onCall(
    (request) async => {'pong': request.dataAsMap['value']},
    callableOptions: HttpsCallableOptions(cors: true, region: regionBelgium),
  );
}

Future<void> main() async {
  var simServer = await firebaseSimServe(
    FirebaseLocal(),
    plugins: [
      FirebaseFunctionsCallSimPlugin(
        firebaseFunctionsService: firebaseFunctionsServiceSim,
        options: FirebaseFunctionsCallSimPluginOptions(
          initFunction: initFunctions,
          httpPort: 0,
        ),
      ),
    ],
  );
  // Creates the default app and starts the http functions server.
  await simServer.initializeAppAsync(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );
  print('sim websocket: ${simServer.uri}');
  print('http functions: ${simServer.httpFunctionsUri}');
}
```

### Call a sim-served function over http

```dart
import 'package:tekartik_firebase_functions_sim/firebase_functions_sim.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http_io/http_io.dart';

Future<void> main() async {
  var functions = firebaseFunctionsServiceSim.functions(
    newFirebaseAppLocal(options: FirebaseAppOptions(projectId: 'my-project')),
  );
  functions['echov1'] = functions.https.onRequest((request) async {
    await request.response.send(requestBodyAsText(request.body));
  });
  var server = await functions.serve(port: 0);

  var client = httpFactoryIo.client.newClient();
  try {
    print(
      await httpClientRead(
        client,
        httpMethodPost,
        server.uri.replace(path: 'echov1'),
        body: 'hello',
      ),
    ); // hello
  } finally {
    client.close();
    await server.close();
  }
}
```

### Shared test suite against the sim service

```dart
@TestOn('vm')
library;

import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_http/test/firebase_functions_test_context_http.dart';
import 'package:tekartik_firebase_functions_sim/firebase_functions_sim.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart'
    as common;
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http_io/http_client_io.dart';
import 'package:test/test.dart';

Future<void> main() async {
  var projectId = 'testsimproject';
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: projectId),
  );
  var firestore = firestoreServiceMemory.firestore(app);
  var functions = firebaseFunctionsServiceSim.functions(app);
  functions.init(firestore: firestore);

  var context = setupFirebaseFunctionsTestServer(
    testContext: FirebaseFunctionsTestContextHttp(
      firebaseFunctions: functions,
      httpClientFactory: httpClientFactoryIo,
    ),
    firestore: firestore,
  );
  var server = await context.serve(port: 0);

  group('firebase_functions_sim', () {
    common.ffTest(testContext: context, projectId: projectId);
    tearDownAll(() async {
      await server.close();
    });
  });
}
```
