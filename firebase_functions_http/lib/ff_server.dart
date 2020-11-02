import 'package:tekartik_http/http_server.dart';

abstract class FfServer {
  Uri get uri;

  Future<void> close();
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
