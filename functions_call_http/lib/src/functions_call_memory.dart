import 'package:tekartik_firebase_functions_call_http/functions_call_http.dart';
import 'package:tekartik_http/http.dart';

/// Default functions call service memory.
final firebaseFunctionsCallServiceMemory = FirebaseFunctionsCallServiceHttp(
    httpClientFactory: httpClientFactoryMemory);
