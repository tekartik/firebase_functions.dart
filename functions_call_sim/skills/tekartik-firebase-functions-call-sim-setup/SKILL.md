---
name: tekartik-firebase-functions-call-sim-setup
description: >-
  Use when calling https callable functions through the Tekartik firebase
  simulator (websocket/json-rpc) with tekartik_firebase_functions_call_sim:
  FirebaseFunctionsCallServiceSim, FirebaseFunctionsCallSim, the client
  functions_call_sim.dart import, and the server side
  functions_call_sim_server.dart import with FirebaseFunctionsCallSimPlugin,
  FirebaseFunctionsCallSimPluginOptions, FirebaseFunctionSimAppInitFunction,
  simServer.httpFunctionsUri / firebaseSimHttpServerUri and firebaseSimServe.
---

# tekartik_firebase_functions_call_sim: callables over the sim channel

`tekartik_firebase_functions_call_sim` implements
`tekartik_firebase_functions_call` on top of the Tekartik firebase simulator:
the client sends the call over the sim websocket (json-rpc service
`firebase_functions`) and a `FirebaseSimServer` plugin runs the real
`onCall` handler in the server process. It also starts the http functions
server so the same functions stay reachable over plain http.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_firebase_functions_call_sim:
      git:
        url: https://github.com/tekartik/firebase_functions.dart
        path: functions_call_sim
  ```
  It brings `tekartik_firebase_functions_call`, `tekartik_firebase_sim` and
  the http/io function implementations.
* Two entry points, do not mix them up:
  * client: `package:tekartik_firebase_functions_call_sim/functions_call_sim.dart`
    re-exports `functions_call.dart` and adds
    `FirebaseFunctionsCallServiceSim`, `FirebaseFunctionsCallSim` and
    `firebaseSimHttpServerUri`;
  * server: `package:tekartik_firebase_functions_call_sim/functions_call_sim_server.dart`
    adds `FirebaseFunctionsCallSimPlugin`,
    `FirebaseFunctionsCallSimPluginOptions`,
    `FirebaseFunctionSimAppInitFunction` and the `FirebaseSimServerFunctionsExt`
    extension (`simServer.httpFunctionsUri`).
* Server side: pass the plugin to `firebaseSimServe`
  (`package:tekartik_firebase_sim/firebase_sim_server.dart`):
  ```
  FirebaseFunctionsCallSimPlugin(
    firebaseFunctionsService: firebaseFunctionsServiceMemory, // or ...Io/Sim
    options: FirebaseFunctionsCallSimPluginOptions(
      initFunction: initFunctions,          // or initFunctions: {projectId: ...}
      httpPort: 0,
    ),
  )
  ```
  The init callback has the shape `void Function({required FirebaseApp
  firebaseApp})` and is called once per app: register the functions there with
  `firebaseFunctionsService.functions(firebaseApp)`. `initFunctions[projectId]`
  wins over `initFunction`; with neither, nothing is registered and no http
  server starts.
* The plugin starts the http functions server itself on the first initialized
  app (`httpPort`, `0` for a free port, `null` for 4999), and only once for the
  whole process: read its uri with `simServer.httpFunctionsUri` (same value as
  `firebaseSimHttpServerUri`) and do not call `serveHttp` yourself.
  `simServer.initializeAppAsync(options: FirebaseAppOptions(projectId: ...))`
  creates the app and runs the plugins eagerly; otherwise it happens when the
  first client connects. `FirebaseFunctionsCallSimPlugin.compat(firebaseFunctions:)`
  is deprecated.
* Client side: the app must be a sim app, i.e. `getFirebaseSim(uri:
  getFirebaseSimLocalhostUri(port: ...), clientFactory: ...)` then
  `await firebase.initializeAppAsync(options: FirebaseAppOptions(projectId:
  ...))` (`package:tekartik_firebase_sim/firebase_sim.dart`). Then
  `FirebaseFunctionsCallServiceSim().functionsCall(app, options:
  FirebaseFunctionsCallOptions(region: regionBelgium))`; `region` is required
  but unused by the sim transport, `baseUri` is ignored. Passing a non sim app
  fails an assert.
* `callable('namev1').call<T>(parameters)` json encodes the parameters, runs
  the `onCall` handler on the server and returns a
  `FirebaseFunctionsCallableResult<T>`; a server side `HttpsError` is rebuilt
  and rethrown client side (any other exception arrives as
  `HttpsErrorCode.internal`). Only `https.onCall` functions are reachable this
  way - an `onRequest` function must be called over
  `simServer.httpFunctionsUri`. `callableFromUri` is not implemented by the sim
  client (it throws `UnimplementedError`), and
  `FirebaseFunctionsCallableOptions` (timeout, App Check) is ignored.
* Caller identity: pass the auth sim instance to propagate the signed-in user,
  `FirebaseFunctionsCallServiceSim(firebaseAuthSim: firebaseAuthSim)`
  (`package:tekartik_firebase_auth_sim/auth_sim.dart`). Its current user's uid
  is sent with the request and surfaces as `request.context.auth?.uid` in the
  handler. Without it the call is anonymous (`uid` is `null`). This is a
  simulation: no token is verified.
* Tests: run both ends in one process with
  `webSocketChannelServerFactoryMemory` / `webSocketChannelClientFactoryMemory`
  (`package:tekartik_app_web_socket/web_socket.dart`) and the memory functions
  service; then `ffCallTestGroup(testContext:
  FirebaseFunctionsCallTestClientContext(functionsCall: ...))`,
  `CallFunctionTestClient` and `ffTest`/`ffFsTest` with a
  `FirebaseFunctionsTestClientContext.baseUrl(baseUrl:
  simServer.httpFunctionsUri.toString(), ...)` from
  `tekartik_firebase_functions_test`. `debugFirebaseSimServer` and
  `debugFirebaseSimClient` turn on protocol logging. Close with
  `simServer.close()`.
* Anti-patterns: importing `functions_call_sim_server.dart` in client/browser
  code; registering functions outside the plugin init callback (the sim server
  would not see them); expecting `callableFromUri`; reusing the plugin http
  port across several sim servers in one process.

## Examples

### Sim server exposing the functions of a project

```dart
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim_server.dart';
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

const projectId = 'my-project';

/// Called once per app by the plugin.
void initFunctions({required FirebaseApp firebaseApp}) {
  var functions = firebaseFunctionsServiceIo.functions(firebaseApp);
  functions['pingv1'] = functions.https.onCall((request) async {
    var uid = request.context.auth?.uid;
    if (uid == null) {
      throw HttpsError(HttpsErrorCode.unauthenticated, 'Sign in required');
    }
    return {'pong': request.dataAsMap['value'], 'uid': uid};
  }, callableOptions: HttpsCallableOptions(cors: true));
}

Future<void> main() async {
  var simServer = await firebaseSimServe(
    FirebaseLocal(),
    plugins: [
      FirebaseFunctionsCallSimPlugin(
        firebaseFunctionsService: firebaseFunctionsServiceIo,
        options: FirebaseFunctionsCallSimPluginOptions(
          initFunctions: {projectId: initFunctions},
          httpPort: 0,
        ),
      ),
    ],
  );
  await simServer.initializeAppAsync(
    options: FirebaseAppOptions(projectId: projectId),
  );
  print('sim: ${simServer.uri} http: ${simServer.httpFunctionsUri}');
}
```

### Client calling through the simulator

```dart
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';

Future<void> main(List<String> args) async {
  var port = args.isNotEmpty ? int.parse(args.first) : null;
  var firebase = getFirebaseSim(uri: getFirebaseSimLocalhostUri(port: port));
  var app = await firebase.initializeAppAsync(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );

  var functionsCall = FirebaseFunctionsCallServiceSim().functionsCall(
    app,
    options: FirebaseFunctionsCallOptions(region: regionBelgium),
  );
  var result = await functionsCall.callable('pingv1').call<Map>({'value': 1});
  print(result.data);
}
```

### In-process test: sim server and sim client over a memory websocket

```dart
@TestOn('vm')
library;

import 'package:tekartik_app_web_socket/web_socket.dart';
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim.dart';
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim_server.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:test/test.dart';

Future<void> main() async {
  var projectId = 'sim_test';
  var simServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryMemory,
    plugins: [
      FirebaseFunctionsCallSimPlugin(
        firebaseFunctionsService: firebaseFunctionsServiceMemory,
        options: FirebaseFunctionsCallSimPluginOptions(
          httpPort: 0,
          initFunctions: {
            projectId: ({required FirebaseApp firebaseApp}) {
              var functions = firebaseFunctionsServiceMemory.functions(
                firebaseApp,
              );
              functions['echov1'] = functions.https.onCall(
                (request) async => request.data,
              );
            },
          },
        ),
      ),
    ],
  );
  var clientApp = await getFirebaseSim(
    clientFactory: webSocketChannelClientFactoryMemory,
    uri: simServer.uri,
  ).initializeAppAsync(options: FirebaseAppOptions(projectId: projectId));
  var functionsCall = FirebaseFunctionsCallServiceSim().functionsCall(
    clientApp,
    options: FirebaseFunctionsCallOptions(region: regionBelgium),
  );

  test('echo', () async {
    var result = await functionsCall.callable('echov1').call<Map>({'a': 1});
    expect(result.data, {'a': 1});
  });
  tearDownAll(() async {
    await simServer.close();
  });
}
```

### Shared callable test suite against the sim client

```dart
@TestOn('vm')
library;

import 'package:tekartik_firebase_functions_call_sim/functions_call_sim.dart';
import 'package:tekartik_firebase_functions_test/constants.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart';
import 'package:test/test.dart';

/// [functionsCall] comes from a sim client connected to a sim server whose
/// functions were registered with initTestFunctions().
void defineTests(FirebaseFunctionsCall functionsCall) {
  var testContext = FirebaseFunctionsCallTestClientContext(
    functionsCall: functionsCall,
  );
  ffCallTestGroup(testContext: testContext);

  late CallFunctionTestClient client;
  setUpAll(() async {
    client = CallFunctionTestClient(
      testContext.functionsCall.callable(callableFunctionTestName),
    );
  });
  test('projectId', () async {
    expect(await client.getProjectId(), isNotNull);
  });
}
```
