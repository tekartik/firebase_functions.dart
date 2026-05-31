import 'dart:typed_data';

import 'package:tekartik_firebase_auth/auth.dart';

import 'import.dart';
import 'mixin.dart';

/// Express HTTP Request HTTP implementation.
class ExpressHttpRequestHttp extends ExpressHttpRequestWrapperBase
    implements ExpressHttpRequest {
  @override
  final dynamic body;

  /// Creates a new [ExpressHttpRequestHttp] instance.
  ExpressHttpRequestHttp(this.body, HttpRequest httpRequest, Uri rewrittenUri)
    : super(httpRequest, rewrittenUri);

  ExpressHttpResponse? _response;

  @override
  ExpressHttpResponse get response =>
      _response ??= ExpressHttpResponseHttp(implHttpRequest.response);
}

/// Express HTTP Response HTTP implementation.
class ExpressHttpResponseHttp extends ExpressHttpResponseWrapperBase
    implements ExpressHttpResponse {
  /// Creates a new [ExpressHttpResponseHttp] instance.
  ExpressHttpResponseHttp(super.implHttpResponse);
}

/// Convert [HttpRequest] to [ExpressHttpRequestHttp].
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

/// Call request HTTP implementation.
class CallRequestHttp with CallRequestMixin implements CallRequest {
  /// The underlying HTTP request.
  final ExpressHttpRequest httpRequest;

  /// User ID.
  String? get uid => httpRequest.headers.value(firebaseFunctionsHttpHeaderUid);
  @override
  late final Object? data = jsonDecode(httpRequest.bodyAsString);

  @override
  late final CallContext context = CallContextNode(this);

  /// Creates a new [CallRequestHttp] instance.
  CallRequestHttp(this.httpRequest);
}

/// Call context node implementation.
class CallContextNode with CallContextMixin implements CallContext {
  /// The associated HTTP call request.
  final CallRequestHttp request;

  /// Creates a new [CallContextNode] instance.
  CallContextNode(this.request);

  @override
  late final CallContextAuth? auth = CallContextAuthNode(this);
}

/// Call context auth node implementation.
class CallContextAuthNode with CallContextAuthMixin implements CallContextAuth {
  /// The associated call context node.
  final CallContextNode context;

  /// Creates a new [CallContextAuthNode] instance.
  CallContextAuthNode(this.context);

  @override
  String? get uid => context.request.uid;

  @override
  DecodedIdToken? get token => null;
}
