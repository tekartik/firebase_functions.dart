// import 'package:tekartik_http/http_server.dart';

import 'package:tekartik_firebase_functions/src/express_http_request.dart';

abstract class FirebaseFunctions {
  Https get https;

  operator []=(String key, dynamic function);
}

typedef void RequestHandler(ExpressHttpRequest request);

abstract class HttpsFunction {}

abstract class Https {
  HttpsFunction onRequest(RequestHandler handler);
}
