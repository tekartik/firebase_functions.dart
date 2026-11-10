/// Calls https callable functions over plain http (development and tests):
/// `firebaseFunctionsCallServiceHttp`, `FirebaseFunctionsCallServiceHttp`,
/// with the `tekartik_firebase_functions_call` API.
library;

export 'package:tekartik_firebase_functions_call/functions_call.dart';

export 'src/functions_call_http.dart'
    show FirebaseFunctionsCallServiceHttp, firebaseFunctionsCallServiceHttp;
