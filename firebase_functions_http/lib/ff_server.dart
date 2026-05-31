import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions_http/src/import.dart';

/// HTTP implementation of the Firebase Functions server.
class FfServerHttp implements FfServer {
  /// The underlying HTTP server instance.
  final HttpServer? httpServer;

  /// Creates a new [FfServerHttp] instance.
  FfServerHttp(this.httpServer);

  @override
  Future<void> close() async {
    await httpServer!.close(force: true);
  }

  @override
  Uri get uri => httpServerGetUri(httpServer!);
}
