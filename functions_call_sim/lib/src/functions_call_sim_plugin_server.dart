import 'dart:convert';

import 'package:cv/cv.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase_functions/utils.dart';
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim_server.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http_mixin.dart';

import 'functions_call_sim_message.dart';

class _CallContextAuthSim with CallContextAuthMixin implements CallContextAuth {
  /// User id;
  @override
  final String? uid;

  _CallContextAuthSim({required this.uid});
}

class _CallContextSim with CallContextMixin implements CallContext {
  @override
  final _CallContextAuthSim auth;

  _CallContextSim({required this.auth});
}

class _CallRequestSim with CallRequestMixin implements CallRequest {
  @override
  final Object? data;
  @override
  late _CallContextSim context;
  _CallRequestSim(this.data, String? userId) {
    context = _CallContextSim(auth: _CallContextAuthSim(uid: userId));
  }
}

/// Sim plugin server implementation
class FirebaseFunctionsCallSimPluginServer {
  /// Firebase auth sim server
  final FirebaseFunctionsCallSimPlugin firebaseFunctionsCallSimPlugin;

  /// Constructor
  FirebaseFunctionsCallSimPluginServer({
    required this.firebaseFunctionsCallSimPlugin,
  });

  /// Get user
  Future<Model> handleFunctionsCallRequest(Map<String, Object?> params) async {
    var callRequest = params.cv<CallSimRequest>();
    var name = callRequest.name.v!;
    var userId = callRequest.userId.v;

    var function =
        firebaseFunctionsCallSimPlugin.firebaseFunctions.functions[name]
            as HttpsCallableFunctionHttp;

    var data = jsonDecode(callRequest.body.v!);
    try {
      var callResult = await function.callHandler(
        _CallRequestSim(data, userId),
      );
      return (CallSimResult()..success.v = jsonEncode(callResult)).toMap();
    } catch (e, st) {
      if (isDebug) {
        // ignore: avoid_print
        print('error $st');
        // ignore: avoid_print
        print(st);
      }
      var httpsError = anyExceptionToHttpsError(e);
      return (CallSimResult()..error.v = httpsErrorToJsonMap(httpsError))
          .toMap();
    }
  }
}
