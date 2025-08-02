import 'package:tekartik_firebase_auth_sim/auth_sim.dart';
import 'package:tekartik_firebase_functions_call/functions_call_mixin.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';

import 'functions_call_sim.dart';
import 'functions_call_sim_message.dart';

/// Firebase functions sim
abstract class FirebaseFunctionsCallServiceSim
    implements FirebaseFunctionsCallService {
  /// Constructor
  factory FirebaseFunctionsCallServiceSim({FirebaseAuthSim? firebaseAuthSim}) =>
      _FirebaseFunctionsCallServiceSim(firebaseAuthSim: firebaseAuthSim);

  /// Auth sim if any
  FirebaseAuthSim? get firebaseAuthSim;
}

class _FirebaseFunctionsCallServiceSim
    with FirebaseFunctionsCallServiceDefaultMixin
    implements FirebaseFunctionsCallServiceSim {
  @override
  final FirebaseAuthSim? firebaseAuthSim;

  /// Most implementation need a single instance, keep it in memory!
  final _instances = <String, FirebaseFunctionsCallSim>{};

  _FirebaseFunctionsCallServiceSim({required this.firebaseAuthSim}) {
    initFunctionsCallSimBuilders();
  }
  FirebaseFunctionsCallSim _getInstance(
    App app,
    String region,
    FirebaseFunctionsCallSim Function() createIfNotFound,
  ) {
    var key = '${app.name}_$region';
    var instance = _instances[key];
    if (instance == null) {
      var newInstance = instance = createIfNotFound();
      _instances[key] = newInstance;
    }
    return instance;
  }

  @override
  FirebaseFunctionsCall functionsCall(
    App app, {
    required FirebaseFunctionsCallOptions options,
  }) {
    return _getInstance(app, options.region, () {
      assert(app is FirebaseAppSim, 'app not compatible (${app.runtimeType})');
      return FirebaseFunctionsCallSim(
        service: this,
        appSim: app as FirebaseAppSim,
        options: options,
      );
    });
  }
}
