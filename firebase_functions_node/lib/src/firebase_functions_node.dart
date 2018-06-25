import 'package:node_io/node_io.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart' as common;
import 'package:firebase_functions_interop/firebase_functions_interop.dart'
    as impl;

FirebaseFunctionsNode _firebaseFunctionsNode;

common.FirebaseFunctions get firebaseFunctionsNode =>
    _firebaseFunctionsNode ??= new FirebaseFunctionsNode._();

//import 'package:firebase_functions_interop/
class FirebaseFunctionsNode implements common.FirebaseFunctions {
  FirebaseFunctionsNode._();

  @override
  final common.Https https = new HttpsNode();

  @override
  operator []=(String key, dynamic function) {
    impl.functions[key] = (function as HttpsFunctionNode).value;
  }
}

class HttpsNode implements common.Https {
  HttpsNode() {}

  @override
  common.HttpsFunction onRequest(common.RequestHandler handler) {
    return new HttpsFunctionNode(
        impl.FirebaseFunctions.https.onRequest(handler));
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
