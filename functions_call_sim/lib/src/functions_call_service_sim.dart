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
    with
        FirebaseProductServiceMixin<FirebaseFunctionsCall>,
        FirebaseFunctionsCallServiceDefaultMixin
    implements FirebaseFunctionsCallServiceSim {
  @override
  final FirebaseAuthSim? firebaseAuthSim;

  /// The instances of each app (the app object, not its name: a new app of
  /// the same name has its own connection), by region and base uri,
  /// released when the app is deleted ([close]).
  final _appInstances = <App, Map<String, FirebaseFunctionsCallSim>>{};

  _FirebaseFunctionsCallServiceSim({required this.firebaseAuthSim}) {
    initFunctionsCallSimBuilders();
  }
  FirebaseFunctionsCallSim _getInstance(
    App app,
    FirebaseFunctionsCallOptions options,
    FirebaseFunctionsCallSim Function() createIfNotFound,
  ) {
    var instances = _appInstances[app];
    if (instances == null) {
      _appInstances[app] = instances = <String, FirebaseFunctionsCallSim>{};
      // close(app) is called when the app is deleted.
      app.addService(this);
    }
    // One instance per region and base uri.
    var key = '${options.region}_${options.baseUri}';
    return instances[key] ??= createIfNotFound();
  }

  @override
  Future<void> close(App app) async {
    _appInstances.remove(app);
    await super.close(app);
  }

  @override
  FirebaseFunctionsCall functionsCall(
    App app, {
    required FirebaseFunctionsCallOptions options,
  }) {
    return _getInstance(app, options, () {
      assert(app is FirebaseAppSim, 'app not compatible (${app.runtimeType})');
      return FirebaseFunctionsCallSim(
        service: this,
        appSim: app as FirebaseAppSim,
        options: options,
      );
    });
  }
}
