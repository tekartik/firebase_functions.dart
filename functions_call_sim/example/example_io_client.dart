import 'package:tekartik_firebase_functions_call_sim/functions_call_sim.dart';
import 'package:tekartik_firebase_functions_test/menu/firebase_functions_call_client_menu.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';

var urlKv = 'firestore_sim_example.url'.kvFromVar(
  defaultValue: 'ws://localhost:${firebaseSimDefaultPort.toString()}',
);

int? get urlKvPort => int.tryParse((urlKv.value ?? '').split(':').last);
Future<void> main(List<String> args) async {
  var firebase = getFirebaseSim(uri: Uri.parse(urlKv.value!));
  var app = firebase.initializeApp();
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
    keyValuesMenu('kv', [urlKv]);
  });
}
