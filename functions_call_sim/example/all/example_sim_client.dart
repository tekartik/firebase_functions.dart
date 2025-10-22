// ignore_for_file: avoid_print

import 'package:tekartik_firebase_functions_call_sim/functions_call_sim.dart';
import 'package:tekartik_firebase_functions_test/menu/firebase_functions_call_client_menu.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';

import 'vars_menu.dart';

const exampleProjectId = 'example_project_id';

Future<void> main(List<String> args) async {
  debugFirebaseSimClient = true;
  var simUri = getFirebaseSimLocalhostUri(port: simPortKvValue);
  print('Using Firebase Sim URI: $simUri');
  var firebase = getFirebaseSim(uri: simUri);
  var app = await firebase.initializeAppAsync(
    options: FirebaseAppOptions(projectId: exampleProjectId),
  );

  var functionsCallService = FirebaseFunctionsCallServiceSim();
  var functionsCall = functionsCallService.functionsCall(
    app,
    options: FirebaseFunctionsCallOptions(region: regionBelgium),
  );
  await mainMenu(args, () {
    firebaseFunctionsCallMainMenu(
      context: FirebaseFunctionsCallMainMenuContext(
        functionsCall: functionsCall,
      ),
    );
    varsMenu();
  });
}
