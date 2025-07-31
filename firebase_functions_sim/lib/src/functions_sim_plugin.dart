import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

import 'functions_sim_server_service.dart';

/// Service plugin
class FirebaseFunctionsSimPlugin implements FirebaseSimPlugin {
  /// Sim server service
  final firebaseFunctionsSimServerService = FirebaseFunctionsSimServerService();

  /// Constructor
  FirebaseFunctionsSimPlugin() {
    firebaseFunctionsSimServerService.firebaseFunctionsSimPlugin = this;
  }

  @override
  FirebaseSimServerService get simService => firebaseFunctionsSimServerService;
}
