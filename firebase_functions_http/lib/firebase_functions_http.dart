/// Firebase functions served by a `tekartik_http` server (one function per
/// first url path segment), the base of the memory, io and sim
/// implementations. See `firebase_functions_memory.dart` for tests.
library;

export 'package:tekartik_firebase_functions/firebase_functions.dart';
export 'package:tekartik_firebase_functions_http/src/firebase_functions_http.dart'
    show
        FirebaseFunctionsHttp,
        FirebaseFunctionsHttpBase,
        FirebaseFunctionsServiceHttp,
        FirebaseFunctionsHttpDefaultMixin;
export 'src/constant.dart' show firebaseFunctionsHttpDefaultPort;
