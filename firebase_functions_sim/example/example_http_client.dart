import 'package:tekartik_app_dev_menu/dev_menu.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_client.dart';
import 'package:tekartik_http_io/http_client_io.dart';

import 'vars_menu.dart';

Future<void> main(List<String> args) async {
  await mainMenu(args, () {
    varsMenu();
    item('Send to echo', () async {
      var port = httpPortKvValue;
      print('port: $port');
      var client = Client();
      var baseUrl = getFirebaseFunctionsHttpLocalhostUri(port: port);

      Uri httpUri(String path) => baseUrl.replace(path: path);
      var echoUri = httpUri('echo');
      print('Echo URI: $echoUri');
      // var env = ShellEnvironment();
      var responseBody = (await client.post(
        echoUri,
        body: 'Hello from local client',
      )).body;
      print('Response: $responseBody');
      client.close();
    });
  });
}
