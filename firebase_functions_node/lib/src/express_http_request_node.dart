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
}
