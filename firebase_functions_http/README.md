# tekartik_firebase_functions_http

Runs `tekartik_firebase_functions` (http and callable functions) on a
`tekartik_http` server: one function per first url path segment. It ships the
in memory implementation (`firebaseFunctionsServiceMemory`, no socket, for
tests) and the `FirebaseFunctionsHttpBase` that
`tekartik_firebase_functions_io` (a real port on the Dart VM) and the sim
implementation build on.

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_functions_http:
    git:
      url: https://github.com/tekartik/firebase_functions.dart
      path: firebase_functions_http
  tekartik_firebase_local:
    git:
      url: https://github.com/tekartik/firebase.dart
      path: firebase_local
  tekartik_http:
    git:
      url: https://github.com/tekartik/http.dart
      path: http
```

A function served and called in memory:

```dart
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http_memory.dart';

Future<void> main() async {
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );
  var functions = firebaseFunctionsServiceMemory.functions(app);
  functions['hello'] = functions.https.onRequest((request) async {
    await request.response.send('Hello ${requestBodyAsText(request.body)}');
  });
  // Register everything, then serve (port 0: any free port).
  var server = await functions.serveHttp(port: 0);

  var client = httpClientFactoryMemory.newClient();
  var response = await client.post(
    httpServerGetUri(server).replace(path: 'hello'),
    body: 'Bob',
  );
  print('${response.statusCode} ${response.body}'); // 200 Hello Bob
  client.close();
  await server.close();
}
```

On the Dart VM, `firebaseFunctionsServiceIo` of
`tekartik_firebase_functions_io` serves the same functions on a real port
(`firebaseFunctionsHttpDefaultPort`, 4999). Callable functions
(`functions.https.onCall`) are called with `tekartik_firebase_functions_call_http`.

## Platforms

The memory implementation runs anywhere (VM, web, Flutter); a real port needs
the Dart VM (`tekartik_firebase_functions_io`).

## What to know

* The memory server binds no socket: reach it with `httpClientFactoryMemory`.
* Only `https.onRequest` / `onRequestV2` / `onCall` functions are served; an
  unknown path answers 404.
* A handler that throws (sync or async) is logged and answered 500 when it
  sent nothing yet, as Cloud Functions does; the server keeps serving.
* Callables use the Firebase wire format (`{"data": ...}` in,
  `{"result": ...}` or `{"error": ...}` out). Another exception than an
  `HttpsError` is an `internal` error whose details hold the exception text:
  do not put secrets in exception messages.
* The caller uid is simulated with the `x-tekartik-firebase-call-uid` header
  (`firebaseFunctionsHttpHeaderUid`), only while
  `debugFirebaseFunctionsHttpAllowCallUidHeader` is true (debug builds): it
  is not authenticated.
* `HttpsOptions(cors: true)` adds the CORS headers; region, memory and
  timeout options are ignored.
* Firestore triggers need `functions.init(firestore: firestore)` and only see
  the writes made through that `Firestore`.

The [tekartik-firebase-functions-http-setup skill](skills/tekartik-firebase-functions-http-setup/SKILL.md)
has more examples (callables, caller uid, test contexts).
