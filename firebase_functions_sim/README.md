# tekartik_firebase_functions_sim

The `tekartik_firebase_functions` implementation of the Tekartik firebase
simulator: `firebaseFunctionsServiceSim` hosts the functions of a project in
a local Dart process (today the `dart:io` service of
`tekartik_firebase_functions_io`), for a dev server or tests. One import
re-exports the functions api, http and io libraries. Dart VM only; sim
clients (browser, Flutter) call the callables with
`tekartik_firebase_functions_call_sim`.

## Getting started

Not on pub.dev, add it as a git dependency:

```yaml
dependencies:
  tekartik_firebase_functions_sim:
    git:
      url: https://github.com/tekartik/firebase_functions.dart
      path: firebase_functions_sim
```

```dart
import 'package:tekartik_firebase_functions_sim/firebase_functions_sim.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );
  var functions = firebaseFunctionsServiceSim.functions(app);
  functions['echo'] = functions.https.onRequest(
    (request) => request.response.send(requestBodyAsText(request.body)),
  );
  var server = await functions.serveHttp(port: 0); // 4999 by default
  print('${httpServerGetUri(server)}echo');
}
```

To expose the functions to sim clients, pass
`FirebaseFunctionsCallSimPlugin(firebaseFunctionsService:
firebaseFunctionsServiceSim, ...)` (`tekartik_firebase_functions_call_sim`)
to `firebaseSimServe`: the plugin registers them per app and serves them
over http itself (do not also call `serveHttp`).

## What to know

* Everything of `tekartik_firebase_functions_io` applies: the server listens
  on all the interfaces, a failing handler is answered 500, the caller uid
  of a callable comes from a simulation header in debug builds only.
* `lib/firebase_functions_sim_server.dart` is an empty placeholder.

The agent skill
[tekartik-firebase-functions-sim-setup](skills/tekartik-firebase-functions-sim-setup/SKILL.md)
has more examples (sim server, http client, shared test suite).
