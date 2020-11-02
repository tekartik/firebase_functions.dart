import 'package:tekartik_firebase_functions_http/src/firebase_functions_memory.dart'
    as memory;

import 'firebase_functions_http.dart';

export 'firebase_functions_http.dart';

FirebaseFunctionsHttp get firebaseFunctionsMemory =>
    memory.firebaseFunctionsMemory;
