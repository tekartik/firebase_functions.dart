import 'package:tekartik_http/http_server.dart';
import 'package:tekartik_firebase_functions/ff_server.dart';

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
