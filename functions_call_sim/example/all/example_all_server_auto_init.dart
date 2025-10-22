// ignore_for_file: avoid_print

import 'package:tekartik_firebase_functions_call_sim/functions_call_sim_server.dart';
import 'package:tekartik_firebase_functions_sim/firebase_functions_sim.dart';

import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

import 'vars_menu.dart';

Future<void> main() async {
  debugFirebaseSimServer = true;
  // var env = ShellEnvironment();
  var httpPort = httpPortKvValue;

  var functionsService = firebaseFunctionsServiceSim;

  void initFunctions({required FirebaseApp firebaseApp}) {
    var functions = functionsService.functions(firebaseApp);
    initTestFunctions(firebaseFunctions: functions);
  }

  var firebaseSimServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryIo,
    port: simPortKvValue,
    plugins: [
      FirebaseFunctionsCallSimPlugin(
        firebaseFunctionsService: functionsService,
        options: FirebaseFunctionsCallSimPluginOptions(
          httpPort: httpPort,
          initFunction: initFunctions,
        ),
      ),
      //FirebaseFunctionsCallSimPlugin.compat(firebaseFunctions: functions),
    ],
  );

  await firebaseSimServer.initializeAppAsync();
  print('wsUri: ${firebaseSimServer.uri}');
  print('httpFunctionsUri: ${firebaseSimServer.httpFunctionsUri}');
  /*
  // var server = await firebaseSimServe(firebase, port: simPortKvValue);
  print('Firebase Sim Server running at ${firebaseSimServer.uri}');
  var ff = firebaseFunctionsServiceSim.functions(app);
  ff['echo'] = ff.https.onRequestV2(HttpsOptions(cors: true), echoHandler);
  var httpServer = await ff.serveHttp(port: httpPort);
  print(httpServerGetUri(httpServer));*/
}
