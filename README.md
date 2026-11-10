# firebase_functions.dart

Firebase Cloud Functions written in Dart against a common interface, and the
implementations to serve and call them locally. Git packages, not on pub.dev.

| Package | Path | What |
|---|---|---|
| `tekartik_firebase_functions` | [firebase_functions](firebase_functions) | the interface (https, callable, triggers, scheduler, task queues); start here |
| `tekartik_firebase_functions_http` | [firebase_functions_http](firebase_functions_http) | http implementation, in process (`firebaseFunctionsServiceMemory`) for tests |
| `tekartik_firebase_functions_io` | [firebase_functions_io](firebase_functions_io) | the same on a Dart io http server |
| `tekartik_firebase_functions_sim` | [firebase_functions_sim](firebase_functions_sim) | the same with the Firebase simulation server |
| `tekartik_firebase_functions_call` | [functions_call](functions_call) | the interface to call a callable function |
| `tekartik_firebase_functions_call_http` | [functions_call_http](functions_call_http) | call over http (or in memory) |
| `tekartik_firebase_functions_call_sim` | [functions_call_sim](functions_call_sim) | call through the simulation server |
| `tekartik_firebase_functions_test` | [firebase_functions_test](firebase_functions_test) | shared test functions and helpers |

The Cloud Functions runtimes are in other repos:
`tekartik_firebase_functions_admin_sdk` (Dart, in
[firebase_admin_sdk.dart](https://github.com/tekartik/firebase_admin_sdk.dart))
and `tekartik_firebase_functions_node` (node, in
[firebase_node.dart](https://github.com/tekartik/firebase_node.dart)).

See the [firebase_functions package README](firebase_functions/README.md) to
get started.
