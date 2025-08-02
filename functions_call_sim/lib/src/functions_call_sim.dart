import 'package:meta/meta.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';

import 'functions_call_service_sim.dart';

/// Firebase functions sim
abstract class FirebaseFunctionsCallSim implements FirebaseFunctionsCall {
  /// Constructor
  @protected
  factory FirebaseFunctionsCallSim(
    FirebaseFunctionsCallServiceSim service,
    FirebaseApp firebaseApp, {
    required FirebaseFunctionsCallOptions options,
  }) => _FirebaseFunctionsCallSim(service, firebaseApp, options);
}

class _FirebaseFunctionsCallSim
    with
        FirebaseAppProductMixin<FirebaseFunctionsCall>,
        FirebaseFunctionsCallDefaultMixin
    implements FirebaseFunctionsCallSim {
  final FirebaseFunctionsCallOptions callOptions;
  @override
  FirebaseApp get app => firebaseApp;
  final FirebaseApp firebaseApp;
  @override
  final FirebaseFunctionsCallServiceSim service;
  _FirebaseFunctionsCallSim(this.service, this.firebaseApp, this.callOptions);
}
