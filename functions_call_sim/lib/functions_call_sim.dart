/// Client side of the callable functions through the Tekartik firebase
/// simulator: [FirebaseFunctionsCallServiceSim] calls the `onCall` functions
/// of a sim server over the sim websocket (no `dart:io`: VM, web, Flutter).
/// Re-exports `tekartik_firebase_functions_call`.
library;

export 'package:tekartik_firebase_functions_call/functions_call.dart';

export 'src/functions_call_service_sim.dart'
    show FirebaseFunctionsCallServiceSim;
export 'src/functions_call_sim.dart' show FirebaseFunctionsCallSim;
export 'src/functions_call_sim_plugin.dart' show firebaseSimHttpServerUri;
