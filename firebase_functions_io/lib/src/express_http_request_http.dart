import 'dart:async';

import 'package:tekartik_firebase_functions/firebase_functions.dart';

class ExpressHttpRequestHttp extends ExpressHttpRequestWrapperBase
    implements ExpressHttpRequest {
  @override
  final dynamic body;

  ExpressHttpRequestHttp(this.body, HttpRequest httpRequest, Uri rewrittenUri)
      : super(httpRequest, rewrittenUri);

  ExpressHttpResponse _response;

  @override
  ExpressHttpResponse get response =>
      _response ??= ExpressHttpResponseHttp(implHttpRequest.response);
}

class ExpressHttpResponseHttp extends ExpressHttpResponseWrapperBase
    implements ExpressHttpResponse {
  ExpressHttpResponseHttp(HttpResponse implHttpResponse)
      : super(implHttpResponse);
}

Future<ExpressHttpRequestHttp> asExpressHttpRequestHttp(
    HttpRequest httpRequest, Uri rewrittenUri) async {
  final body = <int>[];
  if (httpRequest.contentLength != 0) {
    for (var data in await httpRequest.toList()) {
      body.addAll(data);
    }
  }
  return ExpressHttpRequestHttp(body, httpRequest, rewrittenUri);
}
