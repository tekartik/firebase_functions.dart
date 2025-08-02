import 'package:meta/meta.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_functions_call/functions_call_mixin.dart';
import 'package:tekartik_firebase_functions_call_sim/src/functions_callable_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';

import 'functions_call_service_sim.dart';

/// Firebase functions sim
abstract class FirebaseFunctionsCallSim implements FirebaseFunctionsCall {
  /// Constructor
  @protected
  factory FirebaseFunctionsCallSim({
    required FirebaseFunctionsCallServiceSim service,
    required FirebaseAppSim appSim,
    required FirebaseFunctionsCallOptions options,
  }) => _FirebaseFunctionsCallSim(service, appSim, options);

  /// Call sim service
  FirebaseFunctionsCallServiceSim get serviceSim;

  /// App sim
  FirebaseAppSim get appSim;
}

class _FirebaseFunctionsCallSim
    with
        FirebaseAppProductMixin<FirebaseFunctionsCall>,
        FirebaseFunctionsCallDefaultMixin
    implements FirebaseFunctionsCallSim {
  final FirebaseFunctionsCallOptions callOptions;
  @override
  FirebaseApp get app => appSim;
  @override
  final FirebaseAppSim appSim;
  @override
  final FirebaseFunctionsCallServiceSim serviceSim;
  @override
  FirebaseFunctionsCallService get service => serviceSim;

  _FirebaseFunctionsCallSim(this.serviceSim, this.appSim, this.callOptions);

  @override
  FirebaseFunctionsCallable callable(
    String name, {
    FirebaseFunctionsCallableOptions? options,
  }) {
    return FirebaseFunctionsCallableSim(
      name: name,
      functionsCallSim: this,
      options: options,
    );
  }
}
