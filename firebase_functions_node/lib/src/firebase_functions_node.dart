import 'package:firebase_functions_interop/firebase_functions_interop.dart'
    as impl;
import 'package:node_io/node_io.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart' as common;
import 'package:tekartik_firebase_functions_node/src/firebase_functions_firestore_node.dart';
import 'package:tekartik_firebase_functions_node/src/firebase_functions_pubsub_node.dart';

import 'firebase_functions_https_node.dart';

FirebaseFunctionsNode _firebaseFunctionsNode;

common.FirebaseFunctions get firebaseFunctionsNode =>
    _firebaseFunctionsNode ??= FirebaseFunctionsNode._();

//import 'package:firebase_functions_interop/
class FirebaseFunctionsNode implements common.FirebaseFunctions {
  FirebaseFunctionsNode._();

  @override
  final common.HttpsFunctions https = HttpsFunctionsNode();

  @override
  final common.FirestoreFunctions firestore = FirestoreFunctionsNode();

  @override
  final common.PubsubFunctions pubsub = PubsubFunctionsNode();

  @override
  operator []=(String key, common.FirebaseFunction function) {
    impl.functions[key] = (function as FirebaseFunctionNode).value;
  }
}

abstract class FirebaseFunctionNode implements common.FirebaseFunction {
  dynamic get value;
}

String get firebaseProjectId {
  return Platform.environment['GCLOUD_PROJECT'];
}

String get firebaseStorageBucketName {
  return '$firebaseProjectId.appspot.com';
}
