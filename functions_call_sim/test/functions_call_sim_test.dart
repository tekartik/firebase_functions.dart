@TestOn('vm')
library;

// ignore_for_file: avoid_print
import 'package:tekartik_app_web_socket/web_socket.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim.dart';
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim_server.dart';
import 'package:tekartik_firebase_functions_call_sim/src/version.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_test/constants.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart'
    as common;
import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_http_io/http_client_io.dart';
import 'package:test/test.dart';

Future<void> main() async {
  // debugFirebaseSimServer = devTrue;
  // debugFirebaseSimClient = devTrue;
  var firebaseServer = FirebaseLocal();
  var projectId = 'sim_test';

  var firestoreService = firestoreServiceMemory;
  // Initialize functions for this project
  var functionsService = firebaseFunctionsServiceMemory;
  var firebaseSimServer = await firebaseSimServe(
    firebaseServer,
    webSocketChannelServerFactory: webSocketChannelServerFactoryMemory,

    plugins: [
      FirebaseFunctionsCallSimPlugin(
        firebaseFunctionsService: firebaseFunctionsServiceMemory,
        options: FirebaseFunctionsCallSimPluginOptions(
          initFunctions: {
            projectId: ({required FirebaseApp firebaseApp}) async {
              var functions = functionsService.functions(firebaseApp);
              var firestore = firestoreService.firestore(firebaseApp);
              initTestFunctions(
                firebaseFunctions: functions,
                firestore: firestore,
                version: packageVersion,
              );
            },
          },
          httpPort: 0,
        ),
      ),
    ],
  );
  var clientApp = await (getFirebaseSim(
    clientFactory: webSocketChannelClientFactoryMemory,
    uri: firebaseSimServer.uri,
  )).initializeAppAsync(options: FirebaseAppOptions(projectId: projectId));
  var clientFunctionsCallService = FirebaseFunctionsCallServiceSim();
  var clientFunctions = clientFunctionsCallService.functionsCall(
    clientApp,
    options: FirebaseFunctionsCallOptions(region: regionBelgium),
  );
  var testContext = FirebaseFunctionsCallTestClientContext(
    functionsCall: clientFunctions,
  );
  var ffTestContext = FirebaseFunctionsTestClientContext.baseUrl(
    httpClientFactory: httpClientFactoryMemory,
    functionsCall: clientFunctions,
    baseUrl: firebaseSimServer.httpFunctionsUri.toString(),
  );
  ffCallTestGroup(testContext: testContext);
  common.ffFsTest(
    testContext: ffTestContext,
    projectId: projectId,
    version: packageVersion,
  );
  common.ffTest(testContext: ffTestContext, projectId: projectId);
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
