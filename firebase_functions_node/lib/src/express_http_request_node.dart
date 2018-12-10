import 'package:node_io/node_io.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:firebase_functions_interop/firebase_functions_interop.dart'
    as impl;

class ExpressHttpRequestNode extends ExpressHttpRequestWrapperBase
    implements ExpressHttpRequest {
  impl.ExpressHttpRequest get nativeInstance =>
      implHttpRequest as impl.ExpressHttpRequest;
  ExpressHttpRequestNode(impl.ExpressHttpRequest httpRequest, Uri rewrittenUri)
      : super(httpRequest, rewrittenUri);

  @override
  dynamic get body => nativeInstance.body;

  ExpressHttpResponse _response;

  @override
  ExpressHttpResponse get response => _response ??=
      ExpressHttpResponseNode(nativeInstance.response as NodeHttpResponse);
}

class ExpressHttpResponseNode extends ExpressHttpResponseWrapperBase
    implements ExpressHttpResponse {
  ExpressHttpResponseNode(HttpResponse implHttpResponse)
      : super(implHttpResponse);
}
