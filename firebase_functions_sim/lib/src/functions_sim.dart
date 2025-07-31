import 'package:meta/meta.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_sim/src/functions_service_sim.dart';

/// Firebase functions sim
abstract class FirebaseFunctionsSim implements FirebaseFunctions {
  /// Constructor
  @protected
  factory FirebaseFunctionsSim(
    FirebaseFunctionsServiceSim service,
    FirebaseApp firebaseApp,
  ) => _FirebaseFunctionsSim(service, firebaseApp);
}

class _FirebaseFunctionsSim
    with FirebaseFunctionsDefaultMixin
    implements FirebaseFunctionsSim {
  FirebaseApp get app => firebaseApp;
  final FirebaseApp firebaseApp;
  final FirebaseFunctionsServiceSim service;
  _FirebaseFunctionsSim(this.service, this.firebaseApp);
}
