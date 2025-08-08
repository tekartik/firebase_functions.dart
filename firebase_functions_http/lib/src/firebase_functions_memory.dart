import 'package:tekartik_firebase_local/firebase_local.dart';

import 'firebase_functions_http.dart';
import 'import.dart';

/// Memory service.
class FirebaseFunctionsServiceMemory
    with
        FirebaseProductServiceMixin<FirebaseFunctions>,
        FirebaseFunctionsServiceDefaultMixin
    implements FirebaseFunctionsServiceHttp {
  @override
  FirebaseFunctionsHttp functions(FirebaseApp app) =>
      getInstance(app, () {
            return FirebaseFunctionsMemory._(this, app);
          })
          as FirebaseFunctionsHttp;
}

class FirebaseFunctionsMemory extends FirebaseFunctionsHttpBase {
  FirebaseFunctionsMemory._(
    FirebaseFunctionsServiceHttp firebaseFunctionsService,
    FirebaseApp firebaseApp,
  ) : super(firebaseFunctionsService, firebaseApp, httpServerFactoryMemory);
}

FirebaseFunctionsMemory? _firebaseFunctionsMemory;

FirebaseFunctionsMemory get firebaseFunctionsMemory =>
    _firebaseFunctionsMemory ??=
        firebaseFunctionsServiceMemory.functions(newFirebaseAppLocal())
            as FirebaseFunctionsMemory;

/// The global memory service.
final firebaseFunctionsServiceMemory = FirebaseFunctionsServiceMemory();
