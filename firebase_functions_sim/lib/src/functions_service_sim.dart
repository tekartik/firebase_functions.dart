import 'package:tekartik_firebase_functions/firebase_functions.dart';

import 'functions_sim.dart';

/// Firebase functions sim
abstract class FirebaseFunctionsServiceSim implements FirebaseFunctionsService {
  @override
  FirebaseFunctionsSim functions(FirebaseApp app);

  /// Constructor
  factory FirebaseFunctionsServiceSim() => _FirebaseFunctionsServiceSim();
}

class _FirebaseFunctionsServiceSim
    with FirebaseFunctionsServiceDefaultMixin
    implements FirebaseFunctionsServiceSim {
  @override
  FirebaseFunctionsSim functions(FirebaseApp app) {
    return FirebaseFunctionsSim(this, app);
  }
}
