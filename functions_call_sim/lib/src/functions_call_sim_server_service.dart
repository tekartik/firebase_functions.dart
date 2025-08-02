import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

import 'functions_call_sim_message.dart';
import 'functions_call_sim_plugin.dart';

/// Sim server service
class FirebaseFunctionsCallSimServerService
    extends FirebaseSimServerServiceBase {
  /// Firebase auth sim plugin
  late FirebaseFunctionsCallSimPlugin firebaseFunctionsCallSimPlugin;

  /// Service name
  static final serviceName = 'firebase_functions';

  /// Sim server service
  FirebaseFunctionsCallSimServerService() : super(serviceName) {
    initFunctionsCallSimBuilders();
  }
}
