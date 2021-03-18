import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_http/http.dart';
import 'package:tekartik_http/http_memory.dart';

/// Test
abstract class FirebaseFunctionsTestContext {
  final FirebaseFunctions firebaseFunctions;
  final HttpClientFactory httpClientFactory;
  final String? baseUrl;

  FirebaseFunctionsTestContext(
      {required this.firebaseFunctions,
      required this.httpClientFactory,
      this.baseUrl});

  String url(String path);

  Future<FfServer> serve();
}
