import 'package:path/path.dart' as p;
import 'package:tekartik_firebase_functions_http/ff_server.dart';
import 'package:tekartik_http/http.dart';
import 'package:tekartik_http/http_memory.dart';

import 'firebase_functions_http.dart';
import 'firebase_functions_memory.dart';
import 'src/import.dart';

/// Test
class FirebaseFunctionsTestContext {
  final FirebaseFunctionsHttp firebaseFunctions;
  final HttpClientFactory httpClientFactory;
  final String baseUrl;

  // To set when ready
  FfServer server;

  String url(String path) => p.url.join(server.uri.toString(), path);

  FirebaseFunctionsTestContext(
      {@required this.firebaseFunctions,
      @required this.httpClientFactory,
      @required this.baseUrl});

  /// Serve locally
  Future<FfServer> serve() async {
    var server = await firebaseFunctions.serveHttp(port: 0);
    return this.server = FfServerHttp(server);
  }
}

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
}
