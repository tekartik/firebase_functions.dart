import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_node/src/ff_universal_common.dart';
import 'package:tekartik_firebase_functions_node/src/firebase_functions_node.dart';

class FfServerNode implements FfServer {
  @override
  Future<void> close() async {}

  @override
  Uri get uri => null;
}

/// Node implementation
class FirebaseFunctionsNodeUniversal extends FirebaseFunctionsNode
    implements FirebaseFunctionsUniversal {
  /// Dummy implementation on node
  @override
  Future<FfServer> serve({int port}) async => FfServerNode();
}

FirebaseFunctionsUniversal firebaseFunctionsUniversal =
    FirebaseFunctionsNodeUniversal();

FirebaseFunctions get firebaseFunctions => firebaseFunctionsNode;
