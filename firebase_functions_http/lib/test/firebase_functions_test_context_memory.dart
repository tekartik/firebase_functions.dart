import 'package:tekartik_firebase_functions_http/test/firebase_functions_test_context_http.dart';

// ignore: depend_on_referenced_packages

import '../src/import.dart';

class FirebaseFunctionsTestContextMemory
    extends FirebaseFunctionsTestContextHttp {
  FirebaseFunctionsTestContextMemory(
      {required super.firebaseFunctions, super.functionsCall})
      : super(
          httpClientFactory: httpClientFactoryMemory,
        );
}
