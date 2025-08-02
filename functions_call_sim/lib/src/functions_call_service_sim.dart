import 'package:tekartik_firebase_functions_call/functions_call.dart';

import 'functions_call_sim.dart';

/// Firebase functions sim
abstract class FirebaseFunctionsCallServiceSim
    implements FirebaseFunctionsCallService {
  /// Constructor
  factory FirebaseFunctionsCallServiceSim() =>
      _FirebaseFunctionsCallServiceSim();
}

class _FirebaseFunctionsCallServiceSim
    with FirebaseFunctionsCallServiceDefaultMixin
    implements FirebaseFunctionsCallServiceSim {
  @override
  FirebaseFunctionsCall functionsCall2(
    App app, {
    required FirebaseFunctionsCallOptions options,
  }) => FirebaseFunctionsCallSim(this, app, options: options);
}
