# tekartik_firebase_functions_call

The platform neutral client API to call Firebase https callable functions
(`functions.https.onCall`) from Dart: `FirebaseFunctionsCall`,
`FirebaseFunctionsCallable.call()`, `FirebaseFunctionsCallableResult`.
Interfaces only: the implementation is picked by the entry point of the app.

| Implementation | Package (this repo unless noted) | Runs on |
|---|---|---|
| `firebaseFunctionsCallServiceHttp` | `tekartik_firebase_functions_call_http` | Dart VM, web (over http) |
| `firebaseFunctionsCallServiceMemory` | `tekartik_firebase_functions_call_http` | in process, with the memory function server, for tests |
| `FirebaseFunctionsCallServiceSim` | `tekartik_firebase_functions_call_sim` | a simulation server |
| `firebaseFunctionsCallServiceFlutter` | `tekartik_firebase_functions_call_flutter` ([firebase_flutter](https://github.com/tekartik/firebase_flutter)) | Flutter (native SDK) |
| `firebaseFunctionsCallServiceRest` | `tekartik_firebase_functions_call_rest` ([firebase_rest.dart](https://github.com/tekartik/firebase_rest.dart)) | Dart VM, web, as the signed in REST user |

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_functions_call:
    git:
      url: https://github.com/tekartik/firebase_functions.dart
      path: functions_call
  # One implementation, here http (and memory for the example).
  tekartik_firebase_functions_call_http:
    git:
      url: https://github.com/tekartik/firebase_functions.dart
      path: functions_call_http
```

A callable defined and served in process, then called (offline, the
function side needs `tekartik_firebase_functions_http` and
`tekartik_firebase_local`):

```dart
// functions_call_memory.dart exports functions_call.dart.
import 'package:tekartik_firebase_functions_call_http/functions_call_memory.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: 'demo-project'),
  );
  // The server side: a callable adding a and b.
  var functions = firebaseFunctionsServiceMemory.functions(app);
  functions['addv1'] = functions.https.onCall((request) {
    var data = request.dataAsMap;
    return (data['a'] as int) + (data['b'] as int);
  });
  var server = await functions.serve(port: 0);

  // The client side, the code to write once.
  var functionsCall = firebaseFunctionsCallServiceMemory.functionsCall(
    app,
    options: FirebaseFunctionsCallOptions(
      region: regionBelgium,
      baseUri: server.uri,
    ),
  );
  var result = await functionsCall.callable('addv1').call<int>({
    'a': 1,
    'b': 2,
  });
  print(result.data); // 3

  await server.close();
  await app.delete();
}
```

Against deployed functions, use `firebaseFunctionsCallServiceHttp` with the
`baseUri` of the functions (`https://<region>-<project>.cloudfunctions.net`),
or `callableFromUri(uri)` for a 2nd gen function url.

## What to know

* Parameters and results are json values (`null`, `String`, `num`, `bool`,
  `List`, `Map`): no `DateTime`, no custom class.
* `result.data` is the `result` of the function response, already unwrapped.
  `dataAsMapOrNull` gives the map, or null for anything else (a number
  included); `dataAsMap` throws when it is not a map; `dataAsText` gives a
  `String` as is, a `Map` or a `List` json encoded, and throws for a number,
  a bool or null.
* Errors are `HttpsError`s (`HttpsErrorCode.notFound`, `unauthenticated`,
  `deadlineExceeded` on a timeout...) of
  `package:tekartik_firebase_functions/firebase_functions.dart` (not
  re-exported here).
* `FirebaseFunctionsCallableOptions(timeout:)` defaults to 60 seconds.
* Shared code depends on this package only and receives a
  `FirebaseFunctionsCall`; `functions_call_mixin.dart` has the mixins to
  write a fake (every member throws `UnimplementedError` until overridden).

The [tekartik-firebase-functions-call-client skill](skills/tekartik-firebase-functions-call-client/SKILL.md)
has more examples (client class, http wiring, a fake for unit tests).
