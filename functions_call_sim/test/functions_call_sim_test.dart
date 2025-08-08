@TestOn('vm')
library;

// ignore_for_file: avoid_print
import 'package:tekartik_app_web_socket/web_socket.dart';
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim.dart';
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim_server.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_test/constants.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:test/test.dart';

Future<void> main() async {
  var firebaseServer = FirebaseLocal();
  var projectId = 'sim_test';
  // Initialize functions for this project
  var functionsService = firebaseFunctionsServiceMemory;
  var firebaseSimServer = await firebaseSimServe(
    firebaseServer,
    webSocketChannelServerFactory: webSocketChannelServerFactoryMemory,

    /*
    var serverApp = firebaseServer.initializeApp();
  var serverFunctionsService = firebaseFunctionsServiceMemory;
  var serverFunctions = serverFunctionsService.functions(serverApp);
  initTestFunctions(firebaseFunctions: serverFunctions);

     */
    plugins: [
      FirebaseFunctionsCallSimPlugin(
        firebaseFunctionsService: firebaseFunctionsServiceMemory,
        options: FirebaseFunctionsCallSimPluginOptions(
          initFunctions: {
            projectId: ({required FirebaseApp firebaseApp}) async {
              var functions = functionsService.functions(firebaseApp);
              initTestFunctions(firebaseFunctions: functions);
            },
          },
        ),
      ),
    ],
  );
  var clientApp = (getFirebaseSim(
    clientFactory: webSocketChannelClientFactoryMemory,
    uri: firebaseSimServer.uri,
  )).initializeApp(options: FirebaseAppOptions(projectId: projectId));
  var clientFunctionsCallService = FirebaseFunctionsCallServiceSim();
  var clientFunctions = clientFunctionsCallService.functionsCall(
    clientApp,
    options: FirebaseFunctionsCallOptions(region: regionBelgium),
  );
  var testContext = FirebaseFunctionsCallTestClientContext(
    functionsCall: clientFunctions,
  );
  ffCallTestGroup(testContext: testContext);
  late CallFunctionTestClient client;

  setUpAll(() async {
    client = CallFunctionTestClient(
      testContext.functionsCall.callable(callableFunctionTestName),
    );
  });
  test('projectId', () async {
    expect(await client.getProjectId(), projectId);
  });
  tearDownAll(() async {
    await firebaseSimServer.close();
  });
}
