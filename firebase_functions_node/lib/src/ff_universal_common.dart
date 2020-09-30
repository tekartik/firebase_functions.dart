import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_io/src/firebase_functions_http.dart'; // ignore: implementation_imports

abstract class FfServer {
  Uri get uri;

  Future<void> close();
}

/// Allow running a main as a node or io app
abstract class FirebaseFunctionsUniversal extends FirebaseFunctions {
  /// No effect on node
  Future<FfServer> serve({int port});
}

class FfServerHttp implements FfServer {
  final HttpServer httpServer;

  FfServerHttp(this.httpServer);

  @override
  Future<void> close() async {
    await httpServer.close(force: true);
  }

  @override
  Uri get uri => httpServerGetUri(httpServer);
}

class FirebaseFunctionsHttpUniversal extends FirebaseFunctionsHttp
    implements FirebaseFunctionsUniversal {
  FirebaseFunctionsHttpUniversal(HttpServerFactory httpServerFactory)
      : super(httpServerFactory);

  @override
  Future<FfServer> serve({int port}) async {
    var httpServer = await serveHttp(port: port);
    if (httpServer != null) {
      return FfServerHttp(httpServer);
    }
    return null;
  }
}

final FirebaseFunctionsUniversal firebaseFunctionsUniversalMemory =
    FirebaseFunctionsHttpUniversal(httpServerFactoryMemory);
