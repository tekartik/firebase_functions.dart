import 'package:tekartik_firebase_functions_sim/src/functions_sim_message.dart';
import 'package:tekartik_firebase_functions_sim/src/functions_sim_plugin.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

/// Sim server service
class FirebaseFunctionsSimServerService extends FirebaseSimServerServiceBase {
  /// Firebase auth sim plugin
  late FirebaseFunctionsSimPlugin firebaseFunctionsSimPlugin;

  /// Service name
  static final serviceName = 'firebase_functions';

  /// Sim server service
  FirebaseFunctionsSimServerService() : super(serviceName) {
    initFunctionsSimBuilders();
  }
}
