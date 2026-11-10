# tekartik_firebase_functions_io

The `tekartik_firebase_functions` API served on a real port with `dart:io`:
the functions of `tekartik_firebase_functions_http` (http and callable
functions, Firestore triggers on a local Firestore) bound to an io http
server. For local development, tests, or a Dart server image. Dart VM only.

## Getting started

Not on pub.dev, add it as a git dependency:

```yaml
dependencies:
  tekartik_firebase_functions_io:
    git:
      url: https://github.com/tekartik/firebase_functions.dart
      path: firebase_functions_io
```

```dart
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );
  var functions = firebaseFunctionsServiceIo.functions(app);
  functions['hello'] = functions.https.onRequest(
    (request) => request.response.send('Hello'),
  );
  functions['echo'] = functions.https.onCall((request) => request.data);
  var server = await functions.serveHttp(port: 0); // default port 4999
  print('${httpServerGetUri(server)}hello');
}
```

Call the callables with `tekartik_firebase_functions_call_http`.

## What to know

* The server listens on all the interfaces of the machine.
* A failing handler is answered 500, the server keeps serving.
* The caller uid of a callable is read from a simulation header in debug
  builds only (see `tekartik_firebase_functions_http`): this is not an
  authenticated server.
* The top level `serve({port, publicDir})` also answers the other paths with
  the files of `publicDir` (`public` by default, `index.html` for a folder),
  nothing outside of it.

The agent skill
[tekartik-firebase-functions-io-setup](skills/tekartik-firebase-functions-io-setup/SKILL.md)
has more examples (shared test suite, callable client).
