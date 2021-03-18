import 'package:path/path.dart' as p;
import 'package:tekartik_firebase_functions_http/ff_server.dart';
import 'package:tekartik_http/http.dart';
import 'package:tekartik_http/http_memory.dart';

import 'firebase_functions_http.dart';
import 'firebase_functions_memory.dart';
import 'src/import.dart';

class FirebaseFunctionsTestContextMemory extends FirebaseFunctionsTestContext {
  FirebaseFunctionsTestContextMemory(
      {

      /// external client factory
      HttpClientFactory httpClientFactory})
      : super(
          httpClientFactory: httpClientFactoryMemory,
          firebaseFunctions: firebaseFunctionsMemory,
          baseUrl: null,
        );

  // To set when ready
  @override
  FfServer server;

  @override
  String url(String path) => p.url.join(server.uri.toString(), path);

  /// Serve locally
  Future<FfServer> serve() async {
    var server = await firebaseFunctions.serveHttp(port: 0);
    return this.server = FfServerHttp(server);
  }
}
