import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

import 'functions_call_sim_server_service.dart';

/// Service plugin
class FirebaseFunctionsCallSimPlugin implements FirebaseSimPlugin {
  /// Sim server service
  final firebaseFunctionsCallSimServerService =
      FirebaseFunctionsCallSimServerService();

  /// Constructor
  FirebaseFunctionsCallSimPlugin() {
    firebaseFunctionsCallSimServerService.firebaseFunctionsCallSimPlugin = this;
  }

  @override
  FirebaseSimServerService get simService =>
      firebaseFunctionsCallSimServerService;
}
