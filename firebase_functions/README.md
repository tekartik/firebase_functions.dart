# Setup

```yaml
  tekartik_firebase_functions:
    git:
      url: https://github.com/tekartik/firebase_functions.dart
      path: firebase_functions
    version: '>=0.3.9'
```

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
  error of a task whose last attempt failed is kept in `taskErrors`.
- On the dart3 runtime, `tekartik_firebase_functions_admin_sdk` gives
  `taskQueueServiceAdminSdk(app)` (Cloud Tasks through the admin sdk) and
  `firebase.taskQueueHandler(handler)` for the native
  `firebase.tasks.onTaskDispatched`.

```dart
var tasks = TaskQueueServiceMemory()
  ..onTaskDispatched('cleanupv1', (request) async {
    print('cleanup ${request.data}');
  }, maxAttempts: 3);
await tasks.taskQueue('cleanupv1').enqueue({'day': '2026-10-13'});
await tasks.waitForTasks();
```
