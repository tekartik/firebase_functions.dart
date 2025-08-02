import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

import 'functions_call_sim_server_service.dart';

/// Service plugin
class FirebaseFunctionsCallSimPlugin implements FirebaseSimPlugin {
  /// functions call implementation
  final FirebaseFunctionsHttp firebaseFunctions;

  /// Sim server service
  final firebaseFunctionsCallSimServerService =
      FirebaseFunctionsCallSimServerService();

  /// Constructor
  FirebaseFunctionsCallSimPlugin({required this.firebaseFunctions}) {
    firebaseFunctionsCallSimServerService.firebaseFunctionsCallSimPlugin = this;
  }

  @override
  FirebaseSimServerService get simService =>
      firebaseFunctionsCallSimServerService;
}
