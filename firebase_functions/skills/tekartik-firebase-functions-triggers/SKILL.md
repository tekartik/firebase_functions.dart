---
name: tekartik-firebase-functions-triggers
description: >-
  Use when adding non-HTTP Firebase Cloud Functions in Dart with
  tekartik_firebase_functions: Firestore document triggers
  (functions.firestore.document(path).onWrite/onCreate/onUpdate/onDelete,
  Change, DocumentSnapshot, EventContext) and Cloud Scheduler cron functions
  (functions.scheduler.onSchedule, ScheduleOptions, ScheduleEvent), including
  what the io/memory/sim implementations support when testing them locally.
---

# tekartik_firebase_functions triggers

Firestore document triggers and scheduled (cron) functions on the same
`FirebaseFunctions` as the HTTPS functions. They run for real on node
(`tekartik_firebase_functions_node`) and admin sdk
(`tekartik_firebase_functions_admin_sdk`); http/memory/sim only simulate `onWrite`.

## Guidelines

* Import `package:tekartik_firebase_functions/firebase_functions.dart` (it
  exports the firestore and scheduler libraries). `Firestore` and `Timestamp`
  (type of `EventContext.timestamp`) need
  `package:tekartik_firebase_firestore/firestore.dart`.
* `functions.firestore.document('users/{userId}')` returns a `DocumentBuilder`.
  `onWrite` and `onUpdate` take a `ChangeEventHandler<DocumentSnapshot>`
  (`(Change<DocumentSnapshot> change, EventContext context)`), `onCreate` and
  `onDelete` a `DataEventHandler<DocumentSnapshot>` (`(DocumentSnapshot
  snapshot, EventContext context)`). Register the returned `FirestoreFunction`
  with `functions['name'] = ...`; call `document(path)` again for each trigger.
* `Change(after, before)` exposes `change.after` and `change.before`. Check
  `snapshot.exists` before reading `snapshot.data`: `onWrite` also fires on
  create and delete. `snapshot.ref` is the `DocumentReference` (`path`, `update`).
* `context.params` holds the wildcard values (`context.params['userId']`);
  `context.eventType` and `context.timestamp` describe the event.
* Handlers receive no `Firestore`: keep the one built from the same
  `FirebaseApp` in the class that registers the functions. Never write
  unconditionally to the document that fired the trigger (compare
  before/after first) or the function loops. `await` every write.
* Memory/io/sim implementation (`FirebaseFunctionsHttp`): call
  `functions.init(firestore: firestore)` before registering a trigger (else
  `StateError`). Only `onWrite` is implemented (`onCreate`, `onUpdate`,
  `onDelete` throw `UnimplementedError`); it listens to
  `firestore.doc(path).onSnapshot()` in-process, so the path must be a
  concrete document (no `{wildcard}`), and every `EventContext` member throws.
* Scheduler: `functions.scheduler.onSchedule(ScheduleOptions(schedule: '0 23 *
  * *', timeZone: 'Europe/Paris', region: regionBelgium), handler)` where
  `ScheduleHandler` is `FutureOr<void> Function(ScheduleEvent event)`; register
  the returned `ScheduleFunction`. `schedule` is unix-cron or AppEngine
  syntax (`'every 5 minutes'`). `ScheduleOptions` extends `GlobalOptions`
  (`timeoutSeconds`, `memory`, `region`/`regions`, `concurrency`) but has no
  `maxInstances`. `event.jobName` and `event.scheduleTime` are `null` when
  the job is run manually (console or emulator): log them, do not rely on them.
* `functions.scheduler` throws `UnimplementedError` on the http/memory/sim
  implementation (and on `FirebaseFunctionsDefaultMixin`): wrap the cron
  registration in a `try/catch` or skip it when running locally, and put the
  work in a plain method (`handleCron()`) that tests call directly.
* `functions.pubsub.schedule(expression).timeZone(tz).onRun(handler)`
  (`ScheduleBuilder`, `ScheduleContext`) is the deprecated v1 API.
* `functions.globalOptions = GlobalOptions(region: regionBelgium)` applies to
  triggers registered afterwards; deploy Firestore triggers in a region
  compatible with the database region. For mocks mix in
  `FirestoreFunctionsDefaultMixin`, `DocumentBuilderDefaultMixin`,
  `SchedulerFunctionsDefaultMixin` and `SchedulerEventDefaultMixin`.

## Examples

### Firestore write trigger mirroring a document

```dart
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';

const functionOnTrigger = 'ontriggerv1';
const triggerPath = 'app/trigger/in';
const triggerPathOut = 'app/trigger/out';

class TriggerServerApp {
  final FirebaseFunctions functions;
  final Firestore firestore;
  TriggerServerApp({required this.functions, required this.firestore});

  FirestoreFunction get triggerFunction =>
      functions.firestore.document(triggerPath).onWrite(triggerHandler);
  Future<void> triggerHandler(
    Change<DocumentSnapshot> change,
    EventContext context,
  ) async {
    var after = change.after;
    if (!after.exists) {
      await firestore.doc(triggerPathOut).delete();
      return;
    }
    await firestore.doc(triggerPathOut).set({
      'value': after.data['value'],
      'timestamp': Timestamp.now(),
    });
  }

  void initFunctions() {
    functions.globalOptions = GlobalOptions(region: regionBelgium);
    functions[functionOnTrigger] = triggerFunction;
  }
}
```

### Create and update triggers on a wildcard path

```dart
import 'package:tekartik_firebase_functions/firebase_functions.dart';

void initUserFunctions(FirebaseFunctions functions) {
  functions['onusercreatedv1'] = functions.firestore
      .document('users/{userId}')
      .onCreate((snapshot, context) async {
        var userId = context.params['userId'];
        await snapshot.ref.update({'id': userId, 'createdAt': DateTime.now()});
      });
  functions['onuserupdatedv1'] = functions.firestore
      .document('users/{userId}')
      .onUpdate((change, context) async {
        if (change.before.data['email'] != change.after.data['email']) {
          await change.after.ref.update({'emailVerified': false});
        }
      });
}
```

### Scheduled function

```dart
import 'package:tekartik_firebase_functions/firebase_functions.dart';

const functionDailyCron = 'dailycronv1';

class CronServerApp {
  final FirebaseFunctions functions;
  CronServerApp({required this.functions});

  /// The actual work, also called directly from tests.
  Future<void> handleCron() async {}

  Future<void> dailyCronHandler(ScheduleEvent event) async {
    // Both are null when the job is triggered manually.
    // ignore: avoid_print
    print('cron ${event.jobName} at ${event.scheduleTime}');
    await handleCron();
  }

  void initFunctions() {
    try {
      // Every day at 11pm, Paris time.
      functions[functionDailyCron] = functions.scheduler.onSchedule(
        ScheduleOptions(
          schedule: '0 23 * * *',
          timeZone: 'Europe/Paris',
          region: regionBelgium,
        ),
        dailyCronHandler,
      );
    } catch (e) {
      // No scheduler on the local http/memory/sim implementation.
    }
  }
}
```

### Testing an onWrite trigger with the memory implementation

```dart
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';
// plus the file defining TriggerServerApp, triggerPath and triggerPathOut.
void main() {
  test('onWrite trigger', () async {
    var app = newFirebaseAppLocal(
      options: FirebaseAppOptions(projectId: 'testproject'),
    );
    var firestore = firestoreServiceMemory.firestore(app);
    var functions = firebaseFunctionsServiceMemory.functions(app);
    // Required before registering firestore triggers on this implementation.
    functions.init(firestore: firestore);
    TriggerServerApp(functions: functions, firestore: firestore).initFunctions();
    await firestore.doc(triggerPath).set({'value': 1});
    await firestore.doc(triggerPath).set({'value': 2});
    // The handler runs asynchronously on the snapshot stream: poll.
    DocumentSnapshot out;
    do {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      out = await firestore.doc(triggerPathOut).get();
    } while (!out.exists || out.data['value'] != 2);
  });
}
```
