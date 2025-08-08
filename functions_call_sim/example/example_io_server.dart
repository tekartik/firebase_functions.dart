// ignore_for_file: avoid_print

import 'package:tekartik_firebase_functions_call_sim/functions_call_sim_server.dart';
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

import 'example_io_client.dart';

Future<void> main(List<String> args) async {
  var firebaseLocal = FirebaseLocal();
  var app = firebaseLocal.initializeApp();
  var functionsService = firebaseFunctionsServiceIo;
  var functions = functionsService.functions(app);
  initTestFunctions(firebaseFunctions: functions);
  var firebaseSimServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryIo,
    port: urlKvPort,
    plugins: [
      FirebaseFunctionsCallSimPlugin.compat(firebaseFunctions: functions),
    ],
  );
  print('url ${firebaseSimServer.url}');
}
