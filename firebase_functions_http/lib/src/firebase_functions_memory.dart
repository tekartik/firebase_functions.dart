import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_http/http.dart';

import 'firebase_functions_http.dart';

class FirebaseFunctionsMemory extends FirebaseFunctionsHttpBase {
  FirebaseFunctionsMemory._() : super(httpServerFactoryMemory);
}

FirebaseFunctionsMemory? _firebaseFunctionsMemory;

FirebaseFunctionsMemory get firebaseFunctionsMemory =>
    _firebaseFunctionsMemory ??= FirebaseFunctionsMemory._();
