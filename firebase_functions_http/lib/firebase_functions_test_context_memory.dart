import 'package:path/path.dart' as p;
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart'; // ignore: depend_on_referenced_packages

import 'ff_server.dart';
import 'firebase_functions_memory.dart';
import 'src/import.dart';

class FirebaseFunctionsTestContextMemory extends FirebaseFunctionsTestContext {
  FirebaseFunctionsTestContextMemory(
      {
      /// external client factory
      HttpClientFactory? httpClientFactory})
      : super(
          httpClientFactory: httpClientFactoryMemory,
          firebaseFunctions: firebaseFunctionsMemory,
          baseUrl: null,
        );

  // To set when ready
  late FfServer server;

  @override
  String url(String path) => p.url.join(server.uri.toString(), path);

  /// Serve locally
  @override
  Future<FfServer> serve() async {
    var server =
        await (firebaseFunctions as FirebaseFunctionsHttp).serveHttp(port: 0);
    return this.server = FfServerHttp(server);
  }
}
