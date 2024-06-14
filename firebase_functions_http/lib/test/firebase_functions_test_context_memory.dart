import 'package:tekartik_firebase_functions_http/test/firebase_functions_test_context_http.dart';
// ignore: depend_on_referenced_packages

import '../firebase_functions_memory.dart';
import '../src/import.dart';

class FirebaseFunctionsTestContextMemory
    extends FirebaseFunctionsTestContextHttp {
  FirebaseFunctionsTestContextMemory()
      : super(
          httpClientFactory: httpClientFactoryMemory,
          firebaseFunctions: firebaseFunctionsMemory,
        );
}
