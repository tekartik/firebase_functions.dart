import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_functions_io/src/import.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';

Future<void> main() async {
  // var env = ShellEnvironment();
  int? port;
  var ff = firebaseFunctionsIo;
  ff['echo'] = ff.https.onRequestV2(HttpsOptions(cors: true), echoHandler);
  var server = await ff.serveHttp(port: port);
  print(httpServerGetUri(server));
}
