import 'package:tekartik_firebase_functions_call_sim/functions_call_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

/// Extension to get functions uri from firebase sim server
extension FirebaseSimServerFunctionsExt on FirebaseSimServer {
  /// Get functions http uri
  Uri get httpFunctionsUri => firebaseSimHttpServerUri;
}
