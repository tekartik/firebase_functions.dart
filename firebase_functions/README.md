# tekartik_firebase_functions

Write Firebase Cloud Functions in Dart once, against an abstraction
(`FirebaseFunctions`): https and callable functions, Firestore triggers,
scheduled functions and task queues. The entry point of the server picks the
implementation:

| Implementation | Package | Runs on |
|---|---|---|
| `firebaseFunctionsServiceIo` | `tekartik_firebase_functions_io` (this repo) | a Dart http server (Cloud Run, VM) |
| `firebaseFunctionsServiceMemory` | `tekartik_firebase_functions_http` (this repo) | in process, for tests |
| `firebaseFunctionsServiceSim` | `tekartik_firebase_functions_sim` (this repo) | a simulation server |
| `firebaseFunctionsServiceAdminSdk` | `tekartik_firebase_functions_admin_sdk` ([firebase_admin_sdk.dart](https://github.com/tekartik/firebase_admin_sdk.dart)) | Cloud Functions in Dart |
| `firebaseFunctionsNode` | `tekartik_firebase_functions_node` ([firebase_node.dart](https://github.com/tekartik/firebase_node.dart)) | Cloud Functions on node (dart2js) |

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_functions:
    git:
      url: https://github.com/tekartik/firebase_functions.dart
      path: firebase_functions
```

Define the functions in code that only depends on this package:

```dart
import 'package:tekartik_firebase_functions/firebase_functions.dart';

void initFunctions(FirebaseFunctions functions) {
  functions.globalOptions = GlobalOptions(region: regionBelgium);
  // https: GET/POST https://<region>-<project>.cloudfunctions.net/hellov1
  functions['hellov1'] = functions.https.onRequest((request) async {
    await request.response.send('Hello ${request.uri.queryParameters['name']}');
  });
  // callable: {"data": {"a": 1, "b": 2}} gives {"result": 3}
  functions['addv1'] = functions.https.onCall((request) {
    var data = request.dataAsMap;
    var a = data['a'], b = data['b'];
    if (a is! int || b is! int) {
      throw HttpsError(HttpsErrorCode.invalidArgument, 'a and b expected');
    }
    return a + b;
  });
}
```

Then serve them, here in process (`tekartik_firebase_functions_http` and
`tekartik_firebase_local` in your dev dependencies):

```dart
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http/http.dart';

Future<void> main() async {
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: 'demo-project'),
  );
  var functions = firebaseFunctionsServiceMemory.functions(app);
  initFunctions(functions);
  var server = await functions.serve(port: 0);
  var client = httpClientFactoryMemory.newClient();
  print(await client.read(server.uri.replace(path: '/hellov1', query: 'name=Bob')));
  client.close();
  await server.close();
}
```

`firebaseFunctionsServiceIo.functions(app)` (`tekartik_firebase_functions_io`)
serves the same functions from a Dart http server.

## Task queues

`package:tekartik_firebase_functions/firebase_functions_tasks.dart` (not
exported by `firebase_functions.dart`) abstracts Cloud Tasks queues: a
`TaskQueueService` gives the `TaskQueue` of a task queue function (its name
is the queue name) to `enqueue(data)` tasks, handled by a
`TaskQueueHandler` receiving a `TaskQueueRequest` (`data`, `id`,
`queueName`, `retryCount`, `executionCount`); a throw asks for a retry.

- `TaskQueueServiceMemory` runs everything in process (tests, in memory
  backends): `onTaskDispatched(name, handler, maxAttempts:)` registers a
  handler, `waitForTasks()` waits until no task is pending or running, the
  error of a task whose last attempt failed is kept in `taskErrors`. The
  handler gets the map given to `enqueue` as is (no JSON round trip, as
  Cloud Tasks does): keep JSON values in it.
- On the dart3 runtime, `tekartik_firebase_functions_admin_sdk` gives
  `taskQueueServiceAdminSdk(app)` (Cloud Tasks through the admin sdk) and
  `firebase.taskQueueHandler(handler)` for the native
  `firebase.tasks.onTaskDispatched`.

```dart
import 'package:tekartik_firebase_functions/firebase_functions_tasks.dart';

Future<void> main() async {
  var tasks = TaskQueueServiceMemory()
    ..onTaskDispatched('cleanupv1', (request) async {
      print('cleanup ${request.data}');
    }, maxAttempts: 3);
  await tasks.taskQueue('cleanupv1').enqueue({'day': '2026-10-13'});
  await tasks.waitForTasks();
  await tasks.close();
}
```

## Common pitfalls

* A request handler must finish the response: `await response.send(body)`
  (or `close()` after `write`).
* Function names are the url path: lowercase, no underscore, versioned
  (`'hellov1'`) so that a breaking change is a new function.
* A callable answers a JSON value; throw an `HttpsError` for an error the
  client should see (its `details` must be JSON). Any other exception is an
  `internal` error.
* `onCallHandlerAsRequestHandler` (`utils.dart`) answers an internal error
  with the text of the exception in its details: do not use it where that
  text is private.
* The in process implementations simulate only part of the triggers:
  Firestore `onWrite` only, no scheduler.

Skills: [https and callable functions](skills/tekartik-firebase-functions-https/SKILL.md),
[triggers, scheduler, task queues](skills/tekartik-firebase-functions-triggers/SKILL.md).
