import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'src/firebase_functions_node.dart' as node;
export 'src/firebase_functions_node.dart'
    show firebaseProjectId, firebaseStorageBucketName;

FirebaseFunctions get firebaseFunctionsNode => node.firebaseFunctionsNode;
