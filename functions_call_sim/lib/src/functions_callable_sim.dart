import 'dart:convert';

import 'package:cv/cv.dart';
import 'package:meta/meta.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim.dart';
import 'package:tekartik_firebase_functions/utils.dart';
import 'package:tekartik_firebase_functions_call/functions_call_mixin.dart';
import 'package:tekartik_firebase_functions_call_sim/src/functions_call_sim_message.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';

import 'functions_call_sim.dart';
import 'functions_call_sim_server_service.dart';

/// Callable sim implementation
abstract class FirebaseFunctionsCallableSim
    implements FirebaseFunctionsCallable {
  /// Protected constructor
  @protected
  factory FirebaseFunctionsCallableSim({
    required String name,
    FirebaseFunctionsCallableOptions? options,
    required FirebaseFunctionsCallSim functionsCallSim,
  }) => _FirebaseFunctionsCallableSim(functionsCallSim, name, options);
}

class _FirebaseFunctionsCallableSim
    with FirebaseFunctionsCallableDefaultMixin
    implements FirebaseFunctionsCallableSim {
  @override
  final String name;
  FirebaseFunctionsCallableOptions? options;
  final FirebaseFunctionsCallSim functionsCallSim;
  _FirebaseFunctionsCallableSim(this.functionsCallSim, this.name, this.options);

  FirebaseAppSim get appSim => functionsCallSim.appSim;
  FirebaseAuthSim? get firebaseAuthSim =>
      functionsCallSim.serviceSim.firebaseAuthSim;
  @override
  Future<FirebaseFunctionsCallableResult<T>> call<T>([
    Object? parameters,
  ]) async {
    var currentUserId = (await firebaseAuthSim?.onCurrentUser.first)?.uid;
    var simClient = await appSim.simAppClient;
    var callRequest = CallSimRequest()
      ..name.v = name
      ..userId.setValue(currentUserId)
      ..body.v = jsonEncode(parameters);

    var result = await simClient.sendRequest<Map>(
      FirebaseFunctionsCallSimServerService.serviceName,
      methodFunctionsCall,
      callRequest.toMap(),
    );
    var callSimResult = result.cv<CallSimResult>();
    var error = callSimResult.error.v;
    if (error != null) {
      throw httpsErrorFromJsonMap(error);
    }
    return FirebaseFunctionsCallableResultSim(
      data: jsonDecode(callSimResult.success.v!) as T,
    );
  }
}
