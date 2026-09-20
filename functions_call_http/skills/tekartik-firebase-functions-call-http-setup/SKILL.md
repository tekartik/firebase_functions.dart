---
name: tekartik-firebase-functions-call-http-setup
description: >-
  Use when calling https callable functions over plain http (a local
  tekartik_firebase_functions server, a Cloud Run url, a test) with
  tekartik_firebase_functions_call_http: firebaseFunctionsCallServiceHttp,
  firebaseFunctionsCallServiceMemory, FirebaseFunctionsCallServiceHttp(
  httpClientFactory:), FirebaseFunctionsCallOptions(region:, baseUri:),
  callable/callableFromUri, the firebaseFunctionsHttpCallUri helper, the
  functions_call_http.dart / functions_call_memory.dart /
  functions_call_http_mixin.dart imports, and the uid header sent from the
  current FirebaseAuth user.
---

# tekartik_firebase_functions_call_http: the http callable client

`tekartik_firebase_functions_call_http` implements
`tekartik_firebase_functions_call` with a plain http POST: it is the client
side of a `tekartik_firebase_functions_http` / `_io` / `_sim` server, and the
memory variant talks to the in-process memory server with no socket.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_firebase_functions_call_http:
      git:
        url: https://github.com/tekartik/firebase_functions.dart
        path: functions_call_http
  ```
  It brings `tekartik_firebase_functions_call`; keep shared code on that
  abstraction and inject the `FirebaseFunctionsCall` this package builds.
* Imports:
  * `package:tekartik_firebase_functions_call_http/functions_call_http.dart`
    re-exports `functions_call.dart` (so `FirebaseFunctionsCall`,
    `FirebaseFunctionsCallOptions`, `FirebaseFunctionsCallable`,
    `regionBelgium`, `FirebaseApp`) and adds
    `firebaseFunctionsCallServiceHttp` and the
    `FirebaseFunctionsCallServiceHttp({required HttpClientFactory
    httpClientFactory})` factory;
  * `.../functions_call_memory.dart` re-exports the above and adds
    `firebaseFunctionsCallServiceMemory`;
  * `.../functions_call_http_mixin.dart` adds the low level
    `firebaseFunctionsHttpCallUri(client, uri, {headers, parameters})`.
* `firebaseFunctionsCallServiceHttp` uses `httpClientFactoryUniversal`
  (`package:tekartik_app_http/app_http.dart`): dart:io on the VM, browser
  client on the web. Build your own service when you need a specific factory:
  `FirebaseFunctionsCallServiceHttp(httpClientFactory: httpClientFactoryIo)`,
  `... httpClientFactoryMemory)` (that is exactly
  `firebaseFunctionsCallServiceMemory`).
* `service.functionsCall(app, options: FirebaseFunctionsCallOptions(region:
  regionBelgium, baseUri: httpServerGetUri(server)))` returns a
  `FirebaseFunctionsCall` cached per app name + region.
* `callable('namev1').call<T>(parameters)` posts to
  `<baseUri>/namev1`: `baseUri` is mandatory here, otherwise `call` throws
  `StateError('FirebaseFunctionsCallable.baseUri required')` - this package
  does not compute the production `https://<region>-<project>.cloudfunctions.net`
  endpoint. For a 2nd gen/Cloud Run function pass the full url to
  `callableFromUri(uri)` instead, which ignores `baseUri`.
* Wire format: `POST` with `Content-Type: application/json` and a body
  `{"data": <parameters>}` (cv json encoded, so only JSON values), answer
  `{"result": ...}` returned as `result.data`, or `{"error": {...}}` turned
  back into an `HttpsError`. Any other failure (socket, timeout, non 2xx) is
  converted by `anyExceptionToHttpsError`, so catching `HttpsError`
  (`package:tekartik_firebase_functions/firebase_functions.dart`) is enough.
* Caller identity is a simulation: before each call the client looks up a
  `FirebaseAuth` product registered on the `FirebaseApp` and sends the current
  user's uid in the `x-tekartik-firebase-call-uid` header
  (`firebaseFunctionsHttpHeaderUid`). No ID token, no App Check token is sent,
  and the server only honours it while
  `debugFirebaseFunctionsHttpAllowCallUidHeader` is true. Local development and
  tests only: against a real Firebase deployment the call is anonymous.
* `FirebaseFunctionsCallableOptions` (`timeout`, `limitedUseAppCheckToken`) is
  accepted but currently ignored by this implementation. Each call opens and
  closes its own http client.
* Typical pairs: `firebaseFunctionsCallServiceMemory` +
  `firebaseFunctionsServiceMemory` (`tekartik_firebase_functions_http`) for a
  pure in-process test; `firebaseFunctionsCallServiceHttp` +
  `firebaseFunctionsServiceIo` (`tekartik_firebase_functions_io`) for a real
  port.
* Anti-patterns: using the memory service against a real socket server (or the
  reverse); forgetting `baseUri` with `callable(name)`; expecting real Firebase
  auth/App Check enforcement; keeping one service instance per call instead of
  reusing the app-scoped `FirebaseFunctionsCall`.

## Examples

### In-process test: memory function server + memory callable client

```dart
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: 'dummyproject'),
  );
  late FfServer server;
  late FirebaseFunctionsCall functionsCall;

  setUpAll(() async {
    var functions = firebaseFunctionsServiceMemory.functions(app);
    functions['pingv1'] = functions.https.onCall((request) async {
      var data = request.dataAsMap;
      if (data['command'] != 'ping') {
        throw HttpsError(HttpsErrorCode.invalidArgument, 'Unknown command');
      }
      return {'pong': true};
    });
    server = await functions.serve(port: 0);
    functionsCall = firebaseFunctionsCallServiceMemory.functionsCall(
      app,
      options: FirebaseFunctionsCallOptions(
        region: regionBelgium,
        baseUri: server.uri,
      ),
    );
  });
  tearDownAll(() async {
    await server.close();
  });

  test('ping', () async {
    var result = await functionsCall.callable('pingv1').call<Map>({
      'command': 'ping',
    });
    expect(result.data, {'pong': true});
  });

  test('error', () async {
    try {
      await functionsCall.callable('pingv1').call<Map>({'command': 'nope'});
      fail('should fail');
    } on HttpsError catch (e) {
      expect(e.code, HttpsErrorCode.invalidArgument);
    }
  });
}
```

### Call a function served on a real port

```dart
import 'package:tekartik_firebase_functions_call_http/functions_call_http.dart';
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );
  var functions = firebaseFunctionsServiceIo.functions(app);
  functions['echov1'] = functions.https.onCall(
    (request) async => request.data,
    callableOptions: HttpsCallableOptions(cors: true, region: regionBelgium),
  );
  var httpServer = await functions.serveHttp(port: 0);

  // httpClientFactoryUniversal under the hood (dart:io here).
  var functionsCall = firebaseFunctionsCallServiceHttp.functionsCall(
    app,
    options: FirebaseFunctionsCallOptions(
      region: regionBelgium,
      baseUri: httpServerGetUri(httpServer),
    ),
  );
  var result = await functionsCall.callable('echov1').call<Map>({'value': 1});
  print(result.data); // {value: 1}
  await httpServer.close();
}
```

### The uid of the signed-in user is forwarded (simulation)

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: 'dummyproject'),
  );
  // Registers the FirebaseAuth product the callable client reads.
  var auth = FirebaseAuthServiceSembast(
    databaseFactory: newDatabaseFactoryMemory(),
  ).auth(app);

  var functions = firebaseFunctionsServiceMemory.functions(app);
  functions['whoamiv1'] = functions.https.onCall(
    (request) async => {'uid': request.context.auth?.uid},
  );
  var server = await functions.serve(port: 0);
  var functionsCall = firebaseFunctionsCallServiceMemory.functionsCall(
    app,
    options: FirebaseFunctionsCallOptions(
      region: regionBelgium,
      baseUri: server.uri,
    ),
  );

  var callable = functionsCall.callable('whoamiv1');
  print((await callable.call<Map>({})).data); // {uid: null}
  await auth.getOrCreateUserWithEmailAndPassword(
    email: 'email',
    password: 'password',
  );
  await auth.signInWithEmailAndPassword(email: 'email', password: 'password');
  print((await callable.call<Map>({})).data); // {uid: <uid>}
  await auth.signOut();
  await server.close();
}
```

### Low level: one-off call on an arbitrary uri

```dart
import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_http.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_http_mixin.dart';

Future<void> main() async {
  var client = httpClientFactoryUniversal.newClient();
  try {
    var result = await firebaseFunctionsHttpCallUri<Map>(
      client,
      Uri.parse('http://localhost:4999/pingv1'),
      parameters: {'value': 1},
    );
    print(result.data);
  } finally {
    client.close();
  }
}
```
