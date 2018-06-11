import 'package:tekartik_http/http_server.dart';

abstract class FirebaseFunctions {
  Https get https;

  operator []=(String key, dynamic function);
}

typedef void RequestHandler(HttpRequest request);

abstract class HttpsFunction {}

abstract class Https {
  HttpsFunction onRequest(RequestHandler handler);
}
