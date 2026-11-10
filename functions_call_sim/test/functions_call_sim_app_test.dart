@TestOn('vm')
library;

import 'package:tekartik_app_web_socket/web_socket.dart';
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim.dart';
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim_server.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:test/test.dart';

/// Each project has a function giving its project id.
void main() {
  late FirebaseSimServer firebaseSimServer;
  setUpAll(() async {
    Future<void> initFunctions({required FirebaseApp firebaseApp}) async {
      var functions = firebaseFunctionsServiceMemory.functions(firebaseApp);
      functions['project'] = functions.https.onCall(
        (request) async => firebaseApp.options.projectId,
      );
    }

    firebaseSimServer = await firebaseSimServe(
      FirebaseLocal(),
      webSocketChannelServerFactory: webSocketChannelServerFactoryMemory,
      plugins: [
        FirebaseFunctionsCallSimPlugin(
          firebaseFunctionsService: firebaseFunctionsServiceMemory,
          options: FirebaseFunctionsCallSimPluginOptions(
            initFunctions: {
              'sim_app_test_1': initFunctions,
              'sim_app_test_2': initFunctions,
            },
            httpPort: 0,
          ),
        ),
      ],
    );
  });
  tearDownAll(() async {
    await firebaseSimServer.close();
  });

  Future<FirebaseApp> newClientApp(String projectId) => getFirebaseSim(
    clientFactory: webSocketChannelClientFactoryMemory,
    uri: firebaseSimServer.uri,
  ).initializeAppAsync(options: FirebaseAppOptions(projectId: projectId));

  test('an app re-created with the same name calls its project', () async {
    var service = FirebaseFunctionsCallServiceSim();
    var options = FirebaseFunctionsCallOptions(region: regionBelgium);
    var app1 = await newClientApp('sim_app_test_1');
    var functionsCall1 = service.functionsCall(app1, options: options);
    expect(service.functionsCall(app1, options: options), same(functionsCall1));
    expect(
      (await functionsCall1.callable('project').call<String>()).data,
      'sim_app_test_1',
    );
    await app1.delete();

    // Same (default) name, another project.
    var app2 = await newClientApp('sim_app_test_2');
    var functionsCall2 = service.functionsCall(app2, options: options);
    expect(functionsCall2, isNot(same(functionsCall1)));
    expect(functionsCall2.app, same(app2));
    expect(
      (await functionsCall2.callable('project').call<String>()).data,
      'sim_app_test_2',
    );
    await app2.delete();
  }, timeout: const Timeout(Duration(seconds: 30)));
}
