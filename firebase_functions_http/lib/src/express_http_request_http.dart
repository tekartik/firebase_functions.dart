import 'dart:typed_data';

import 'package:tekartik_firebase_auth/auth.dart';

import 'import.dart';
import 'mixin.dart';

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
  ExpressHttpResponseHttp(super.implHttpResponse);
}

Future<ExpressHttpRequestHttp> asExpressHttpRequestHttp(
  HttpRequest httpRequest,
  Uri rewrittenUri,
) async {
  var body = Uint8List(0);
  if (httpRequest.contentLength != 0) {
    body = await httpStreamGetBytes(httpRequest);
  }
  return ExpressHttpRequestHttp(body, httpRequest, rewrittenUri);
}

class CallRequestHttp with CallRequestMixin implements CallRequest {
  final ExpressHttpRequest httpRequest;

  String? get uid => httpRequest.headers.value(firebaseFunctionsHttpHeaderUid);
  @override
  late final Object? data = jsonDecode(httpRequest.bodyAsString);

  @override
  late final CallContext context = CallContextNode(this);

  CallRequestHttp(this.httpRequest);
}

class CallContextNode with CallContextMixin implements CallContext {
  final CallRequestHttp request;

  CallContextNode(this.request);

  @override
  late final CallContextAuth? auth = CallContextAuthNode(this);
}

class CallContextAuthNode with CallContextAuthMixin implements CallContextAuth {
  final CallContextNode context;

  CallContextAuthNode(this.context);

  @override
  String? get uid => context.request.uid;

  @override
  DecodedIdToken? get token => null;
}
