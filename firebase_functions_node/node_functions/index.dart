import 'package:tekartik_firebase_functions_node/firebase_functions_node.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart'
    as setup;
import 'package:tekartik_http_node/http_client_node.dart';

void main() {
  var context = setup.TestContext();

  context.baseUrl = 'http://localhost:5000/tekartik-free-dev/us-central1';
  setup.setup(
      firebaseFunctions: firebaseFunctionsNode,
      httpClientFactory: httpClientFactoryNode,
      context: context);
}
