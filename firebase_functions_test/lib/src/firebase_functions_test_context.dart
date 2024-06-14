import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';

import 'import.dart';

/// Test
abstract class FirebaseFunctionsTestContext
    implements
        FirebaseFunctionsTestClientContext,
        FirebaseFunctionsTestServerContext {
  @override
  final FirebaseFunctions firebaseFunctions;

  /// External client factory.
  @override
  final HttpClientFactory httpClientFactory;
  @override
  final String? baseUrl;

  FirebaseFunctionsTestContext(
      {required this.firebaseFunctions,
      required this.httpClientFactory,
      this.baseUrl});
}

abstract class FirebaseFunctionsTestServerContext {
  final FirebaseFunctions firebaseFunctions;

  FirebaseFunctionsTestServerContext({
    required this.firebaseFunctions,
  });

  Future<FfServer> serve();
}

/// Test
abstract class FirebaseFunctionsTestClientContext {
  /// External client factory.
  final HttpClientFactory httpClientFactory;
  final String? baseUrl;

  FirebaseFunctionsTestClientContext(
      {required this.httpClientFactory, this.baseUrl});

  String url(String path);
}
