import 'dart:typed_data';

import 'import.dart';

class ExpressHttpRequestHttp extends ExpressHttpRequestWrapperBase
    implements ExpressHttpRequest {
  @override
  final dynamic body;

  ExpressHttpRequestHttp(this.body, HttpRequest httpRequest, Uri rewrittenUri)
      : super(httpRequest, rewrittenUri);

  ExpressHttpResponse? _response;

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
  var body = Uint8List(0);
  if (httpRequest.contentLength != 0) {
    body = await httpStreamGetBytes(httpRequest);
  }
  return ExpressHttpRequestHttp(body, httpRequest, rewrittenUri);
}
