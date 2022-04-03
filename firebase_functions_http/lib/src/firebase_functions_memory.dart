import 'firebase_functions_http.dart';
import 'import.dart';

class FirebaseFunctionsMemory extends FirebaseFunctionsHttpBase {
  FirebaseFunctionsMemory._() : super(httpServerFactoryMemory);
}

FirebaseFunctionsMemory? _firebaseFunctionsMemory;

FirebaseFunctionsMemory get firebaseFunctionsMemory =>
    _firebaseFunctionsMemory ??= FirebaseFunctionsMemory._();
