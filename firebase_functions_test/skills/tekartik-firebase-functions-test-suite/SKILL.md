---
name: tekartik-firebase-functions-test-suite
description: >-
  Use when validating a tekartik_firebase_functions implementation (http,
  memory, io, node, admin sdk, sim) or a functions_call client against the
  shared suite of tekartik_firebase_functions_test: initTestFunctions and
  setupFirebaseFunctionsTestServer to register the standard test functions,
  initFunctionsBasic, then ffTest, ffFsTest, ffCallTestGroup and
  basicTestGroup driven by a FirebaseFunctionsTestClientContext
  (.baseUrl/.urlTemplate), FirebaseFunctionsCallTestClientContext,
  CallFunctionTestClient/HttpFunctionTestClient and FunctionTestInputData.
---

# Shared firebase functions test suite (tekartik_firebase_functions_test)

Backend-agnostic `package:test` suite for `tekartik_firebase_functions`: it
provides a set of standard cloud functions (echo, callable, firestore trigger)
that the implementation under test must register and serve, plus the test
groups that call them over http or through a `functions_call` client. Every
group is a function you call from your own test file, so each implementation
keeps its own `test/` directory.

## Guidelines

* Dependency (not on pub.dev, git only), always a **dev** dependency:
  ```yaml
  dev_dependencies:
    tekartik_firebase_functions_test:
      git:
        url: https://github.com/tekartik/firebase_functions.dart
        path: firebase_functions_test
      version: '>=0.2.1'
  ```
  It brings `tekartik_firebase_functions`, `tekartik_firebase_functions_call`,
  `tekartik_firebase_functions_http`, `tekartik_firebase_firestore`,
  `tekartik_http` and `dev_test`. A concrete implementation
  (`tekartik_firebase_functions_io`, `..._http`, `..._sim`, node, admin sdk), a
  call client (`tekartik_firebase_functions_call_http`) and a `Firestore`
  implementation (`tekartik_firebase_firestore_sembast`) stay your own
  dev dependencies: the suite never picks one.
* Libraries:
  * `package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart`:
    the main one (test side). Re-exports
    `package:tekartik_firebase_functions/firebase_functions.dart` and
    `package:tekartik_http/http_utils.dart`, and exposes the contexts, the
    runners (`ffTest`, `ffFsTest`, `ffCallTestGroup`, `basicTestGroup`), the
    clients and `initFunctionsBasic`.
  * `package:tekartik_firebase_functions_test/firebase_functions_setup.dart`:
    the server side. `initTestFunctions(...)`,
    `setupFirebaseFunctionsTestServer(...)`, `testFunctionNames`, the raw
    handlers (`echoHandler`, `echoBytesHandler`, `echoQueryHandler`,
    `echoFragmentHandler`, `echoHeadersHandler`, `echoInfoHandler`,
    `infoHandler`, `callHandler`, `testHttpFunctionHandler`) and
    `FirestoreTriggerServerTestSetup`.
  * `package:tekartik_firebase_functions_test/constants.dart`: the function
    names (`callableFunctionTestName`, `httpFunctionTestName`,
    `functionCallName`, `functionCallAppCheckName`) and the commands
    (`testCommandData`, `testCommandRaw`, `testCommandThrow`,
    `testCommandNotFound`, `testCommandUserId`, `testCommandProjectId`).
  * `package:tekartik_firebase_functions_test/functions_basic.dart`:
    `basicCallHandler`, `TestApiRequest`, `TestApiResult`,
    `testFunctionsApiInitBuilders()` (registers the cv constructors).
  * `package:tekartik_firebase_functions_test/menu/firebase_functions_call_client_menu.dart`:
    the interactive dev menu, not a test.
  * `package:tekartik_firebase_functions_test/firebase_functions_test.dart` is
    deprecated, import `firebase_functions_test_runner.dart` instead.
* Server side, two levels:
  * `initFunctionsBasic(firebaseFunctions, prefix: 'memory', callHandler: ...)`
    registers a single callable `<prefix>basic` handled by `basicCallHandler`
    (commands `echo`, `not-found`, `project-id`). Enough for `basicTestGroup`.
  * `initTestFunctions(firebaseFunctions: ..., functionNamePrefix: ...,
    firestore: ..., version: ..., testRedirectUrl: ...)` registers the full set
    listed in `testFunctionNames`: `echo`, `echoquery`, `echobytes`,
    `echofragment`, `echoheaders`, `echoinfo`, `ffinfo`, `redirect`, the
    callables and the http test function. Passing both `firestore` and
    `version` also registers the firestore trigger functions
    (`functionSetInTrigger`, `functionGetOutTrigger`, `functionOnTrigger`)
    through `FirestoreTriggerServerTestSetup`, required by `ffFsTest`.
  * `setupFirebaseFunctionsTestServer(testContext: ..., firestore: ...,
    version: ...)` is the same thing driven by a
    `FirebaseFunctionsTestServerContext`: it calls `initTestFunctions` on
    `testContext.firebaseFunctions` and returns the context, which you then
    `serve({port})`. `setup(...)` is the older name, prefer the long one.
    All the functions use `regionBelgium` and `cors: true`.
* Client side, everything is driven by a context:
  * `FirebaseFunctionsTestClientContext.baseUrl(httpClientFactory:, baseUrl:,
    functionsCall:, functionNameSuffix:)` when the functions are served under
    one base url; `...urlTemplate(httpClientFactory:, urlTemplate:,
    functionsCall:)` when each function has its own host, with `{{function}}`
    (or `__function__`) in the template. `context.url('echo')` builds the url,
    `await context.close()` releases it.
  * `FirebaseFunctionsCallTestClientContext(functionsCall: ..., testCallUri:
    ...)` is the lighter, call-only context used by `ffCallTestGroup`.
  * `FirebaseFunctionsTestContext` (abstract, both sides) and
    `FirebaseFunctionsTestServerContext` (abstract, `serve({port})`) are the
    ones an implementation extends; `FirebaseFunctionsTestContextHttp`,
    `FirebaseFunctionsTestServerContextHttp` and
    `FirebaseFunctionsTestClientContextHttp` in
    `tekartik_firebase_functions_http` (`lib/test/`) are ready-made http ones.
* Test groups, all declared at the top level of `main()`:
  * `basicTestGroup(() => testClientContext)` (takes a getter, so the context
    can be built in `setUpAll`): echo, raw echo, not-found, project-id on
    the `basic` function.
  * `ffTest(testContext: ..., httpClientFactory: ..., projectId: ...)`: the
    http surface (post, query, fragment, headers, bytes, info, callables).
  * `ffFsTest(testContext: ..., projectId: ..., version: ...)`: the firestore
    trigger round trip; `version` is a `pub_semver` `Version` (re-exported by
    `package:tekartik_common_utils/version_utils.dart`), usually the
    `packageVersion` of the implementation, and must match the one passed to
    `initTestFunctions`. It has a 2 minutes timeout, triggers are slow.
  * `ffCallTestGroup(testContext: ...)`: the callable
    `callableFunctionTestName` through a `functions_call` client.
* Talking to a test function by hand: `FunctionTestInputData(command:
  testCommandData, data: ..., userId: ..., firebaseApp: ...)` in,
  `FunctionTestOutputData(data: ...)` out. Send it with
  `CallFunctionTestClient(callable)` (callable) or
  `HttpFunctionTestClient(client, uri)` (raw http); both extend
  `FunctionTestClient`, which adds `testData()`, `sendThrow()`,
  `sendNotFound()`, `sendRaw(raw)`, `getUserLoggedIn()`, `getProjectId()` and
  `close()`.
* Build the app, the functions and the server in `setUpAll` (or before the
  groups when synchronous), serve with `port: 0` to get a free port, and always
  close the server and the context in `tearDownAll`.
* Mark VM-only targets with `@TestOn('vm')`; the memory http implementation
  runs everywhere.

## Examples

### Basic callable suite over an in-memory server

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
    var prefix = 'memory';
    var functions = firebaseFunctionsServiceMemory.functions(app);
    // Registers the '<prefix>basic' callable handled by basicCallHandler.
    initFunctionsBasic(functions, prefix: prefix);
    server = await functions.serve(port: 0); // port 0: free port

    testClientContext = FirebaseFunctionsTestClientContext.urlTemplate(
      httpClientFactory: httpClientFactoryMemory,
      urlTemplate: '${server.uri}$prefix{{function}}',
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

### Full http suite with firestore triggers

```dart
import 'package:tekartik_common_utils/version_utils.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_http/test/firebase_functions_test_context_http.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

void main() {
  var projectId = 'dummyproject';
  var version = Version(1, 0, 0); // usually the implementation packageVersion
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: projectId),
  );
  var functions = firebaseFunctionsServiceMemory.functions(app);
  var firestore = firestoreServiceMemory.firestore(app);
  functions.init(firestore: firestore);

  var context = FirebaseFunctionsTestContextHttp(
    httpClientFactory: httpClientFactoryMemory,
    firebaseFunctions: functions,
  );
  // Registers echo/echoquery/.../callables and the firestore triggers.
  setupFirebaseFunctionsTestServer(
    testContext: context,
    firestore: firestore,
    version: version,
  );

  late FfServer server;
  setUpAll(() async {
    server = await context.serve(port: 0);
    context.functionsCall = firebaseFunctionsCallServiceMemory.functionsCall(
      app,
      options: FirebaseFunctionsCallOptions(
        region: regionBelgium,
        baseUri: server.uri,
      ),
    );
  });

  ffTest(testContext: context, projectId: projectId);
  ffFsTest(testContext: context, projectId: projectId, version: version);

  tearDownAll(() async {
    await server.close();
  });
}
```

### Callable-only suite against an already connected client

```dart
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_firebase_functions_test/constants.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart';
import 'package:test/test.dart';

/// [functionsCall] is a client of a server where initTestFunctions() ran.
void defineTests(FirebaseFunctionsCall functionsCall) {
  var testContext = FirebaseFunctionsCallTestClientContext(
    functionsCall: functionsCall,
  );
  ffCallTestGroup(testContext: testContext);

  test('custom command', () async {
    var client = CallFunctionTestClient(
      functionsCall.callable(callableFunctionTestName),
    );
    var output = await client.send(
      FunctionTestInputData(command: testCommandData, data: {'hello': 'world'}),
    );
    expect(output.data, {'hello': 'world'});
    expect(await client.getProjectId(), functionsCall.app.options.projectId);
    await client.close();
  });
}
```

### Register the test functions in a dev/sim server

```dart
import 'package:tekartik_common_utils/version_utils.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';

/// Called by a dev server (sim, io, node) once per project app.
void initServerTestFunctions({
  required FirebaseFunctions functions,
  required Firestore firestore,
}) {
  initTestFunctions(
    firebaseFunctions: functions,
    firestore: firestore, // with version: enables the trigger functions
    version: Version(1, 0, 0),
  );
  // testFunctionNames lists what has been registered.
  print(testFunctionNames);
}
```

### Interactive dev menu on a call client

```dart
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_firebase_functions_test/menu/firebase_functions_call_client_menu.dart';

Future<void> main(List<String> args, FirebaseFunctionsCall functionsCall) async {
  await mainMenu(args, () {
    firebaseFunctionsCallMainMenu(
      context: FirebaseFunctionsCallMainMenuContext(
        functionsCall: functionsCall,
      ),
    );
  });
}
```

## Common mistakes

* Running `ffFsTest` without passing `firestore:` and `version:` to
  `initTestFunctions`/`setupFirebaseFunctionsTestServer`: the trigger functions
  are then never registered.
* Passing a different `version` to the server setup and to `ffFsTest`.
* Leaving `functionsCall` null on the context: `basicTestGroup` and the
  callable parts of `ffTest` dereference it.
* Forgetting the `functionNamePrefix` / url template when the server registers
  the functions under a prefix.
* Building the server inside a `test()` instead of `setUpAll`, or forgetting
  `await server.close()` in `tearDownAll`.
