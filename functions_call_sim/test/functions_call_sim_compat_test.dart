@TestOn('vm')
library;

// ignore_for_file: avoid_print
import 'package:tekartik_app_web_socket/web_socket.dart';
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim.dart';
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim_server.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:test/scaffolding.dart';

Future<void> main() async {
  var firebaseServer = FirebaseLocal();
  var serverApp = firebaseServer.initializeApp(
    options: FirebaseAppOptions(projectId: firebaseSimDefaultProjectId),
  );
  var serverFunctionsService = firebaseFunctionsServiceMemory;
  var serverFunctions = serverFunctionsService.functions(serverApp);
  initTestFunctions(firebaseFunctions: serverFunctions);
  var firebaseSimServer = await firebaseSimServe(
    firebaseServer,
    webSocketChannelServerFactory: webSocketChannelServerFactoryMemory,

    plugins: [
      FirebaseFunctionsCallSimPlugin.compat(firebaseFunctions: serverFunctions),
    ],
  );
  var clientApp = (getFirebaseSim(
    clientFactory: webSocketChannelClientFactoryMemory,
    uri: firebaseSimServer.uri,
  )).initializeApp();
  var clientFunctionsCallService = FirebaseFunctionsCallServiceSim();
  var clientFunctions = clientFunctionsCallService.functionsCall(
    clientApp,
    options: FirebaseFunctionsCallOptions(region: regionBelgium),
  );
  ffCallTestGroup(
    testContext: FirebaseFunctionsCallTestClientContext(
      functionsCall: clientFunctions,
    ),
  );
  tearDownAll(() async {
    await serverApp.delete();
    await firebaseSimServer.close();
  });
}
