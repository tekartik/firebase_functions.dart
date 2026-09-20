---
name: tekartik-firebase-functions-call-client
description: >-
  Use when calling Firebase https callable functions from Dart through the
  tekartik_firebase_functions_call abstraction: FirebaseFunctionsCallService,
  FirebaseFunctionsCallOptions, FirebaseFunctionsCall (callable,
  callableFromUri, instance), FirebaseFunctionsCallable.call<T>(),
  FirebaseFunctionsCallableOptions, FirebaseFunctionsCallableResult (data,
  dataAsMap, dataAsText), the functions_call.dart / functions_call_mixin.dart
  imports, HttpsError handling, and writing fakes with the DefaultMixins.
---

# tekartik_firebase_functions_call: calling callable functions

`tekartik_firebase_functions_call` is the platform neutral client API for
https callable Cloud Functions (the ones written with
`functions.https.onCall`). It contains interfaces only: an implementation
package (http, memory, sim, Flutter native) provides the service.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_firebase_functions_call:
      git:
        url: https://github.com/tekartik/firebase_functions.dart
        path: functions_call
  ```
  Add one implementation, same repo: `path: functions_call_http`
  (`firebaseFunctionsCallServiceHttp`, and `firebaseFunctionsCallServiceMemory`
  from its `functions_call_memory.dart`) or `path: functions_call_sim`
  (`FirebaseFunctionsCallServiceSim`, sim clients). Shared/business code should
  depend on this package only and receive a `FirebaseFunctionsCall`.
* Imports: `package:tekartik_firebase_functions_call/functions_call.dart` for
  consumers (it re-exports `package:tekartik_firebase/firebase.dart` for
  `FirebaseApp`/`FirebaseAppOptions`, plus `regionBelgium`, `regionFrankfurt`,
  `regionUsCentral1`); `package:tekartik_firebase_functions_call/functions_call_mixin.dart`
  only to implement or fake the API (it adds
  `FirebaseFunctionsCallServiceDefaultMixin`,
  `FirebaseFunctionsCallDefaultMixin`,
  `FirebaseFunctionsCallableDefaultMixin`,
  `FirebaseFunctionsCallableResultDefaultMixin`, each member throwing
  `UnimplementedError` until overridden).
* Get an instance from the service:
  `service.functionsCall(app, options: FirebaseFunctionsCallOptions(region:
  regionBelgium, baseUri: serverUri))`. `region` is required (1st gen
  functions), `baseUri` overrides the endpoint and is what local servers and
  tests use; it is ignored on Flutter, where the native SDK resolves the url.
  `functionsCallObsolete(app, region: ...)` is deprecated.
  `FirebaseFunctionsCall.instance` returns the instance registered as a product
  on the default `FirebaseApp` (throws when the platform plugin did not
  register one); `functionsCall.app` and `functionsCall.service` give back the
  app and the service.
* Two ways to reference a function:
  `functionsCall.callable('namev1')` (resolved against the region/`baseUri`
  configuration) and `functionsCall.callableFromUri(uri)` for a 2nd gen
  function whose full url you already know. Both accept
  `options: FirebaseFunctionsCallableOptions(timeout: Duration(seconds: 60),
  limitedUseAppCheckToken: false)`.
* Call with `await callable.call<T>(parameters)`: `parameters` must be JSON
  encodable (`null`, `String`, `num`, `bool`, `List`, `Map`) - no
  `DateTime`, no custom class. The result is a
  `FirebaseFunctionsCallableResult<T>` whose `data` is the `{"result": ...}`
  payload of the function; the extension `FirebaseFunctionsCallableResultExt`
  adds `dataAsMap`, `dataAsMapOrNull` and `dataAsText` for loosely typed
  results. Prefer `call<Map>` / `call<String>` over `call<dynamic>`.
* Errors: implementations throw `HttpsError` (with `HttpsErrorCode` constants
  such as `HttpsErrorCode.notFound`, `unauthenticated`, `permissionDenied`,
  `internal`) from
  `package:tekartik_firebase_functions/firebase_functions.dart`, which is not
  re-exported here: import it in the code that catches. Network failures and
  timeouts arrive as `HttpsError` too.
* Same callable instance can be reused; creating one per call is cheap but the
  `FirebaseFunctionsCall` instance itself is cached per app (and per region by
  the http implementation), so ask the service instead of keeping globals.
* Tests: `FirebaseFunctionsCallableResult<T>(data)` is a public factory for a
  canned result, and the DefaultMixins let a fake implement only `callable` and
  `call`. For an end-to-end test against real function code, use
  `firebaseFunctionsCallServiceMemory` with the memory function server
  (`tekartik_firebase_functions_http`).
* Anti-patterns: depending on an implementation package from shared code;
  calling `callable(name)` on the http implementation without a `baseUri`
  (throws `StateError`); passing non JSON values; catching `Exception` instead
  of `HttpsError`; expecting `data` to contain the `{"result": ...}` wrapper
  (it is already unwrapped).

## Examples

### Implementation-agnostic client code

```dart
import 'package:tekartik_firebase_functions/firebase_functions.dart'
    show HttpsError, HttpsErrorCode;
import 'package:tekartik_firebase_functions_call/functions_call.dart';

/// Depends on the abstraction only: any implementation can be injected.
class ApiClient {
  final FirebaseFunctionsCall functionsCall;

  ApiClient(this.functionsCall);

  late final _api = functionsCall.callable(
    'apiv1',
    options: FirebaseFunctionsCallableOptions(timeout: Duration(seconds: 30)),
  );

  Future<Map<String, Object?>?> command(
    String command, {
    Object? data,
  }) async {
    try {
      var result = await _api.call<Map>({'command': command, 'data': data});
      return result.dataAsMapOrNull;
    } on HttpsError catch (e) {
      if (e.code == HttpsErrorCode.notFound) {
        return null;
      }
      rethrow;
    }
  }
}
```

### Wire an implementation (http) and call by name or by uri

```dart
// needs tekartik_firebase_functions_call_http (path: functions_call_http)
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_http.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );
  FirebaseFunctionsCall functionsCall = firebaseFunctionsCallServiceHttp
      .functionsCall(
        app,
        options: FirebaseFunctionsCallOptions(
          region: regionBelgium,
          baseUri: Uri.parse('http://localhost:4999'),
        ),
      );

  var byName = await functionsCall.callable('pingv1').call<String>('hello');
  print(byName.data);

  // 2nd gen: full url, no region/baseUri involved.
  var byUri = await functionsCall
      .callableFromUri(Uri.parse('https://pingv1-abc123-ew.a.run.app'))
      .call<Map>({'value': 1});
  print(byUri.dataAsMap);
}
```

### Fake implementation for unit tests

```dart
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_functions_call/functions_call_mixin.dart';

typedef FakeCallHandler = Object? Function(Object? parameters);

class FakeFunctionsCallable with FirebaseFunctionsCallableDefaultMixin {
  @override
  final String name;
  final FakeCallHandler handler;

  FakeFunctionsCallable(this.name, this.handler);

  @override
  Future<FirebaseFunctionsCallableResult<T>> call<T>([
    Object? parameters,
  ]) async => FirebaseFunctionsCallableResult<T>(handler(parameters) as T);
}

class FakeFunctionsCall
    with
        FirebaseFunctionsCallDefaultMixin,
        FirebaseAppProductMixin<FirebaseFunctionsCall>
    implements FirebaseFunctionsCall {
  final Map<String, FakeCallHandler> handlers;

  FakeFunctionsCall(this.handlers);

  @override
  FirebaseFunctionsCallable callable(
    String name, {
    FirebaseFunctionsCallableOptions? options,
  }) => FakeFunctionsCallable(name, handlers[name]!);

  @override
  FirebaseApp get app => throw UnimplementedError();

  @override
  FirebaseFunctionsCallService get service => throw UnimplementedError();
}

Future<void> main() async {
  var functionsCall = FakeFunctionsCall({
    'pingv1': (parameters) => {'pong': parameters},
  });
  var result = await functionsCall.callable('pingv1').call<Map>({'value': 1});
  print(result.data); // {pong: {value: 1}}
}
```
