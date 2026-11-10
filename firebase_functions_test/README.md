# tekartik_firebase_functions_test

The shared tests of `tekartik_firebase_functions` implementations (http
memory and io, sim, node, admin sdk) and of `functions_call` clients: a set of
standard functions the server registers (echo, http and callable test
functions, a firestore trigger) and the test groups calling them, plus a
console dev menu. Pure Dart on `package:test`.

## Getting started

Git package, not on pub.dev, used as a dev dependency of the implementation
it tests:

```yaml
dev_dependencies:
  tekartik_firebase_functions_test:
    git:
      url: https://github.com/tekartik/firebase_functions.dart
      path: firebase_functions_test
  test: '>=1.31.0'
```

The basic callable tests on the in memory http server
(`test/functions_memory_basic_test.dart`):

```dart
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

void main() {
  late FirebaseFunctionsTestClientContext testClientContext;
  late FfServer server;

  setUpAll(() async {
    var app = newFirebaseAppMemory();
    var functions = firebaseFunctionsServiceMemory.functions(app);
    // The 'memorybasic' callable, handled by basicCallHandler.
    initFunctionsBasic(functions, prefix: 'memory');
    server = await functions.serve(port: 0);
    testClientContext = FirebaseFunctionsTestClientContext.urlTemplate(
      httpClientFactory: httpClientFactoryMemory,
      urlTemplate: '${server.uri}memory{{function}}',
      functionsCall: firebaseFunctionsCallServiceMemory.functionsCall(
        app,
        options: FirebaseFunctionsCallOptions(region: regionBelgium),
      ),
    );
  });

  basicTestGroup(() => testClientContext);

  tearDownAll(() async {
    await server.close();
    await testClientContext.close();
  });
}
```

Run it with `dart test`.

## Server side, client side

* Server: `initFunctionsBasic` registers the `<prefix>basic` callable;
  `initTestFunctions` (or `setupFirebaseFunctionsTestServer`, in
  `firebase_functions_setup.dart`) registers the full set (`echo`,
  `echoquery`, `echobytes`, `echoinfo`, `echoheaders`, `ffinfo`, the http and
  callable test functions) and, given a `firestore` and a `version`, the
  firestore trigger functions.
* Client: `basicTestGroup` (the basic callable), `ffTest` (the http surface
  and the callables), `ffFsTest` (the trigger round trip, 2 minutes
  timeout), `ffCallTestGroup` (the callable test function through a
  `FirebaseFunctionsCall` client). A `FirebaseFunctionsTestClientContext`
  builds the urls: `.baseUrl(...)` for functions under one base url,
  `.urlTemplate(...)` with `{{function}}` in the template.

## What to know

* `ffFsTest` needs the trigger functions (`initTestFunctions` with
  `firestore:` and `version:`, the same `version` as the test): it fails when
  the trigger does not write its document within 30 s.
* `ffTest` `info` posts to `echoinfo/sub1/sub2`: the function must serve the
  sub path (only the functions named with a `dart` prefix, on the admin sdk,
  may answer 404).
* `FirebaseFunctionsTestClientContext.baseUrl(functionNameSuffix:)` puts that
  value *before* the function name (a prefix, despite its name).
* The functions use `regionBelgium` and `cors: true`; serve with `port: 0`
  and close the server in `tearDownAll`.

More in the
[package skill](skills/tekartik-firebase-functions-test-suite/SKILL.md).
