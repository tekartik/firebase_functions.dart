import 'package:tekartik_firebase_functions_sim/firebase_functions_sim.dart';

import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

import 'vars_menu.dart';

Future<void> main() async {
  // var env = ShellEnvironment();
  var port = httpPortKvValue;
  var firebase = FirebaseLocal();
  var app = firebase.initializeApp();

  var functionsService = firebaseFunctionsServiceSim;

  // var server = await firebaseSimServe(firebase, port: simPortKvValue);
  var ff = functionsService.functions(app);
  ff['echo'] = ff.https.onRequestV2(HttpsOptions(cors: true), echoHandler);
  var httpServer = await ff.serveHttp(port: port);
  print(httpServerGetUri(httpServer));
}
