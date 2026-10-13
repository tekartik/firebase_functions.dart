import 'dart:convert';

import 'package:cv/cv.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim.dart' show DecodedIdToken;
import 'package:tekartik_firebase_functions/utils.dart';
import 'package:tekartik_firebase_functions_call_sim/src/functions_call_sim_plugin.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http_mixin.dart';

import 'functions_call_sim_message.dart';

class _CallContextAuthSim with CallContextAuthMixin implements CallContextAuth {
  /// User id;
  @override
  final String? uid;

  /// No decoded token in the sim (as for http).
  @override
  DecodedIdToken? get token => null;

  _CallContextAuthSim({required this.uid});
}

class _CallContextSim with CallContextMixin implements CallContext {
  /// Null when not authenticated.
  @override
  final _CallContextAuthSim? auth;

  _CallContextSim({required this.auth});
}

class _CallRequestSim with CallRequestMixin implements CallRequest {
  @override
  final Object? data;
  @override
  late _CallContextSim context;
  _CallRequestSim(this.data, String? userId) {
    context = _CallContextSim(
      auth: userId == null ? null : _CallContextAuthSim(uid: userId),
    );
  }
}

/// Sim plugin server implementation
class FirebaseFunctionsCallSimPluginServer {
  /// Firebase app
  final FirebaseFunctionsHttp firebaseFunctions;

  /// Firebase auth sim server
  final FirebaseFunctionsCallSimPlugin firebaseFunctionsCallSimPlugin;

  /// Constructor
  FirebaseFunctionsCallSimPluginServer({
    required this.firebaseFunctionsCallSimPlugin,
    required this.firebaseFunctions,
  });

  /// Get user
  Future<Model> handleFunctionsCallRequest(Map<String, Object?> params) async {
    var callRequest = params.cv<CallSimRequest>();
    var name = callRequest.name.v!;
    var userId = callRequest.userId.v;

    try {
      var function = firebaseFunctions.functions[name];
      if (function is! HttpsCallableFunctionHttp) {
        // Like http, an unknown function (or not a callable one) is not found.
        throw HttpsError(
          HttpsErrorCode.notFound,
          'Not found',
          'callable function $name not found',
        );
      }
      var data = jsonDecode(callRequest.body.v!);
      var callResult = await function.callHandler(
        _CallRequestSim(data, userId),
      );
      return (CallSimResult()..success.v = jsonEncode(callResult)).toMap();
    } catch (e, st) {
      if (isDebug) {
        // ignore: avoid_print
        print('error $e');
        // ignore: avoid_print
        print(st);
      }
      // Same as the http callable functions.
      var httpsError = e is HttpsError
          ? e
          : HttpsError(HttpsErrorCode.internal, 'Internal error', {
              'exception': '$e',
            });
      return (CallSimResult()..error.v = httpsError.toHttpJson()).toMap();
    }
  }
}
