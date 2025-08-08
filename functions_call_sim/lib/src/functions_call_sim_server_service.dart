import 'dart:async';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
import 'package:tekartik_firebase_sim/firebase_sim_mixin.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

import 'functions_call_sim_message.dart';
import 'functions_call_sim_plugin.dart';
import 'functions_call_sim_plugin_server.dart';

/// Sim server service
class FirebaseFunctionsCallSimServerService
    extends FirebaseSimServerServiceBase {
  /// Firebase auth sim plugin
  late FirebaseFunctionsCallSimPlugin firebaseFunctionsCallSimPlugin;
  final _expando = Expando<FirebaseFunctionsCallSimPluginServer>();

  /// Service name
  static final serviceName = 'firebase_functions';

  /// Sim server service
  FirebaseFunctionsCallSimServerService() : super(serviceName) {
    initFunctionsCallSimBuilders();
  }

  @override
  FutureOr<Object?> onCall(
    RpcServerChannel channel,
    RpcMethodCall methodCall,
  ) async {
    try {
      var simServerChannel = firebaseSimServerExpando[channel]!;
      var firebaseAuthSimPluginServer = _expando[channel] ??= () {
        var app = simServerChannel.app!;
        var firebaseFunctionsService =
            firebaseFunctionsCallSimPlugin.firebaseFunctionsService;
        late FirebaseFunctionsHttp firebaseFunctions;
        var options = firebaseFunctionsCallSimPlugin.options;

        var initFunction = options.initFunctions[app.options.projectId];
        if (initFunction == null) {
          // ignore: avoid_print
          print('compat mode');
          // ignore: deprecated_member_use_from_same_package
          firebaseFunctions = firebaseFunctionsCallSimPlugin.firebaseFunctions;
        } else {
          firebaseFunctions = firebaseFunctionsService.functions(app);
          initFunction(firebaseApp: app);
        }
        return FirebaseFunctionsCallSimPluginServer(
          firebaseFunctionsCallSimPlugin: firebaseFunctionsCallSimPlugin,
          firebaseFunctions: firebaseFunctions,
        );
      }();
      var parameters = methodCall.arguments;
      switch (methodCall.method) {
        case methodFunctionsCall:
          var map = resultAsMap(parameters);
          return await firebaseAuthSimPluginServer.handleFunctionsCallRequest(
            map,
          );
      }
      return super.onCall(channel, methodCall);
    } catch (e, st) {
      if (isDebug) {
        // ignore: avoid_print
        print('error $st');
        // ignore: avoid_print
        print(st);
      }
      rethrow;
    }
  }
}
