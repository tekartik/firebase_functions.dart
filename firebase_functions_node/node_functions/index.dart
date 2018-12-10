import 'package:tekartik_firebase_functions_node/firebase_functions_node.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart'
    as setup;
import 'package:tekartik_http_node/http_client_node.dart';

main() {
  setup.setup(
      firebaseFunctions: firebaseFunctionsNode,
      httpClientFactory: httpClientFactoryNode);
}
