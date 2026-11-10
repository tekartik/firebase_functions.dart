# tekartik_firebase_functions_call_http

The client of https callable functions over plain http (the
`tekartik_firebase_functions_call` API): it calls a function served by
`tekartik_firebase_functions_http` (memory), `tekartik_firebase_functions_io`
(a real port) or any server speaking the callable format
(`{"data": ...}` in, `{"result": ...}` or `{"error": ...}` out). For
development and tests: the caller is identified by a simulation header, not
by a Firebase id token. Dart VM, web and Flutter.

## Getting started

Not on pub.dev, add it as a git dependency:

```yaml
dependencies:
  tekartik_firebase_functions_call_http:
    git:
      url: https://github.com/tekartik/firebase_functions.dart
      path: functions_call_http
```

A memory function server and its client, in one process (a test):

```dart
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  var app = newFirebaseAppLocal();
  var functions = firebaseFunctionsServiceMemory.functions(app);
  functions['echo'] = functions.https.onCall((request) => request.data);
  var server = await functions.serve(port: 0);

  var functionsCall = firebaseFunctionsCallServiceMemory.functionsCall(
    app,
    options: FirebaseFunctionsCallOptions(
      region: regionBelgium,
      baseUri: server.uri,
    ),
  );
  var result = await functionsCall.callable('echo').call<Map>({'value': 1});
  print(result.data); // {value: 1}
  await server.close();
  await app.delete();
}
```

## When to use what

* `firebaseFunctionsCallServiceHttp`: a real http client (dart:io on the VM,
  the browser client on the web), for a server on a port
  (`firebaseFunctionsServiceIo`).
* `firebaseFunctionsCallServiceMemory` (`functions_call_memory.dart`): the
  in process memory server of `firebaseFunctionsServiceMemory`, no socket.
* `callable(name)` posts to `<baseUri>/<name>` (`baseUri` required);
  `callableFromUri(uri)` calls a full url.

## What to know

* Errors come back as `HttpsError` (code, message, details), a network
  failure too. `FirebaseFunctionsCallableOptions.timeout` gives a
  `deadline-exceeded` error.
* The uid of the current user of the app's `FirebaseAuth` is sent in the
  `x-tekartik-firebase-call-uid` header, honoured by the tekartik http
  servers in debug builds only: never trust it in production.
* One `FirebaseFunctionsCall` per app, region and base uri, released when the
  app is deleted.

The agent skill
[tekartik-firebase-functions-call-http-setup](skills/tekartik-firebase-functions-call-http-setup/SKILL.md)
has more examples (real port, signed in user, low level call).
