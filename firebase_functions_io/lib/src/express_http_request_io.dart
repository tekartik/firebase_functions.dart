import 'import.dart';

// Check if needed
class ExpressHttpRequestIo extends ExpressHttpRequestWrapperBase
    implements ExpressHttpRequest {
  @override
  final dynamic body;

  ExpressHttpRequestIo(this.body, HttpRequest httpRequest, Uri rewrittenUri)
      : super(httpRequest, rewrittenUri);

  ExpressHttpResponse? _response;

  @override
  ExpressHttpResponse get response =>
      _response ??= ExpressHttpResponseIo(implHttpRequest.response);
}

class ExpressHttpResponseIo extends ExpressHttpResponseWrapperBase
    implements ExpressHttpResponse {
  ExpressHttpResponseIo(super.implHttpResponse);
}

Future<ExpressHttpRequestIo> asExpressHttpRequestIo(
    HttpRequest httpRequest, Uri rewrittenUri) async {
  final body = <int>[];
  if (httpRequest.contentLength != 0) {
    for (var data in await httpRequest.toList()) {
      body.addAll(data);
    }
  }
  return ExpressHttpRequestIo(body, httpRequest, rewrittenUri);
}
