import 'package:node_io/node_io.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart' as common;
import 'package:firebase_functions_interop/firebase_functions_interop.dart'
    as impl;
import 'package:tekartik_firebase_functions_node/src/express_http_request_node.dart';

FirebaseFunctionsNode _firebaseFunctionsNode;

common.FirebaseFunctions get firebaseFunctionsNode =>
    _firebaseFunctionsNode ??= FirebaseFunctionsNode._();

//import 'package:firebase_functions_interop/
class FirebaseFunctionsNode implements common.FirebaseFunctions {
  FirebaseFunctionsNode._();

  @override
  final common.Https https = HttpsNode();

  @override
  operator []=(String key, dynamic function) {
    impl.functions[key] = (function as HttpsFunctionNode).value;
  }
}

class HttpsNode implements common.Https {
  HttpsNode() {}

  @override
  common.HttpsFunction onRequest(common.RequestHandler handler) {
    _handle(impl.ExpressHttpRequest request) {
      var _request = ExpressHttpRequestNode(request, request.uri);
      handler(_request);
    }

    return HttpsFunctionNode(impl.FirebaseFunctions.https.onRequest(_handle));
  }
}

class HttpsFunctionNode implements common.HttpsFunction {
  // ignore: unused_field
  final _implCloudFonction;

  HttpsFunctionNode(this._implCloudFonction);

  get value => _implCloudFonction;

  toString() => _implCloudFonction.toString();
}

String get firebaseProjectId {
  return Platform.environment['GCLOUD_PROJECT'];
}

String get firebaseStorageBucketName {
  return '$firebaseProjectId.appspot.com';
}
