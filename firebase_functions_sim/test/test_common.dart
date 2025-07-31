import 'dart:async';

import 'package:tekartik_app_web_socket/web_socket.dart';
import 'package:tekartik_firebase_functions_sim/functions_sim_server.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

class TestContext {
  late FirebaseSimServer simServer;
  late Firebase firebase;
}

// memory only
Future<TestContext> initTestContextSim() async {
  var firebaseLocalServer = FirebaseLocal();
  var testContext = TestContext();
  var firebaseFunctionsSimPlugin = FirebaseFunctionsSimPlugin();
  // The server use firebase io
  var simServer = testContext.simServer = await firebaseSimServe(
    firebaseLocalServer,
    webSocketChannelServerFactory: webSocketChannelServerFactoryMemory,
    plugins: [firebaseFunctionsSimPlugin],
  );
  testContext.firebase = getFirebaseSim(
    clientFactory: webSocketChannelClientFactoryMemory,
    uri: simServer.uri,
  );

  return testContext;
}

Future close(TestContext testContext) async {
  await testContext.simServer.close();
}
