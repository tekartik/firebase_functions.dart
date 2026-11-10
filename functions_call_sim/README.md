# tekartik_firebase_functions_call_sim

Https callable functions through the Tekartik firebase simulator
(`tekartik_firebase_sim`): the client sends the call over the sim websocket
and a `FirebaseSimServer` plugin runs the `onCall` handler in the server
process. The plugin also serves the functions over plain http. For local
development and tests. Client: Dart VM, web, Flutter; server: Dart VM.

## Getting started

Not on pub.dev, add it as a git dependency:

```yaml
dependencies:
  tekartik_firebase_functions_call_sim:
    git:
      url: https://github.com/tekartik/firebase_functions.dart
      path: functions_call_sim
```

A sim server and its client in one process (a test; the memory websocket
comes from `tekartik_app_web_socket`, `path: app_web_socket` of
https://github.com/tekartik/app_common_utils.dart):

```dart
import 'package:tekartik_app_web_socket/web_socket.dart';
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim.dart';
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim_server.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

Future<void> main() async {
  var simServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryMemory,
    plugins: [
      FirebaseFunctionsCallSimPlugin(
        firebaseFunctionsService: firebaseFunctionsServiceMemory,
        options: FirebaseFunctionsCallSimPluginOptions(
          httpPort: 0,
          // Called once per app: register the functions there.
          initFunction: ({required FirebaseApp firebaseApp}) {
            var functions = firebaseFunctionsServiceMemory.functions(
              firebaseApp,
            );
            functions['echo'] = functions.https.onCall(
              (request) => request.data,
            );
          },
        ),
      ),
    ],
  );
  var app = await getFirebaseSim(
    clientFactory: webSocketChannelClientFactoryMemory,
    uri: simServer.uri,
  ).initializeAppAsync(options: FirebaseAppOptions(projectId: 'my-project'));
  var functionsCall = FirebaseFunctionsCallServiceSim().functionsCall(
    app,
    options: FirebaseFunctionsCallOptions(region: regionBelgium),
  );
  var result = await functionsCall.callable('echo').call<Map>({'value': 1});
  print(result.data); // {value: 1}
  await app.delete();
  await simServer.close();
}
```

Two libraries: `functions_call_sim.dart` for the client (no `dart:io`),
`functions_call_sim_server.dart` for the server plugin.

## What to know

* `callable(name)` and `callableFromUri(uri)` (its last path segment) call
  the `onCall` function of that name; `FirebaseFunctionsCallableOptions.timeout`
  fails with `deadline-exceeded`. An `HttpsError` of the function comes back
  as is, anything else as `internal`.
* The caller uid is the current user of the `firebaseAuthSim` given to
  `FirebaseFunctionsCallServiceSim(firebaseAuthSim:)` (without it the calls
  are anonymous); it is not verified: a simulation.
* The plugin starts one http functions server for the whole process, with
  the functions of the first app initialized (`simServer.httpFunctionsUri`);
  the `onRequest` functions of another project of the same sim server are
  not served there.
* One `FirebaseFunctionsCall` per app object, released when the app is
  deleted.

The agent skill
[tekartik-firebase-functions-call-sim-setup](skills/tekartik-firebase-functions-call-sim-setup/SKILL.md)
has more examples (io sim server, shared test suite).
