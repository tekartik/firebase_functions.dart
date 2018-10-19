import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'dart:async';

class ExpressHttpRequestIo extends ExpressHttpRequestWrapperBase
    implements ExpressHttpRequest {
  final dynamic body;
  ExpressHttpRequestIo(this.body, HttpRequest httpRequest, Uri rewrittenUri)
      : super(httpRequest, rewrittenUri);
}

Future<ExpressHttpRequestIo> asExpressHttpRequestIo(
    HttpRequest httpRequest, Uri rewrittenUri) async {
  List<int> body = [];
  if (httpRequest.contentLength != 0) {
    for (var data in await httpRequest.toList()) {
      body.addAll(data);
    }
  }
  return ExpressHttpRequestIo(body, httpRequest, rewrittenUri);
}
