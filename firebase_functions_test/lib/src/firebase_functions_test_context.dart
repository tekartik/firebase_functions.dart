import 'package:path/path.dart' as p;
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';

import 'import.dart';

/// Test
abstract class FirebaseFunctionsTestContext
    implements
        FirebaseFunctionsTestClientContext,
        FirebaseFunctionsTestServerContext {
  @override
  final FirebaseFunctions firebaseFunctions;

  @override
  FirebaseFunctionsCall? functionsCall;

  /// External client factory.
  @override
  final HttpClientFactory httpClientFactory;
  @override
  final String? baseUrl;

  @override
  final String? functionNamePrefix;
  FirebaseFunctionsTestContext({
    required this.firebaseFunctions,
    required this.httpClientFactory,
    this.functionsCall,
    this.baseUrl,
    this.functionNamePrefix,
  });
}

abstract class FirebaseFunctionsTestServerContext {
  final FirebaseFunctions firebaseFunctions;

  FirebaseFunctionsTestServerContext({required this.firebaseFunctions});

  Future<FfServer> serve({int? port});
}

/// Test
abstract class FirebaseFunctionsTestClientContext {
  /// External client factory.
  final HttpClientFactory httpClientFactory;
  final String? baseUrl;
  FirebaseFunctionsCall? get functionsCall;
  final String? functionNamePrefix;

  FirebaseFunctionsTestClientContext({
    required this.httpClientFactory,
    this.baseUrl,
    this.functionNamePrefix,
  });
  factory FirebaseFunctionsTestClientContext.baseUrl({
    required HttpClientFactory httpClientFactory,
    required String baseUrl,
    FirebaseFunctionsCall? functionsCall,
    String? functionNameSuffix,
  }) {
    return _FirebaseFunctionsTestClientContextBaseUrl(
      httpClientFactory: httpClientFactory,
      baseUrl: baseUrl,
      functionsCall: functionsCall,
      functionNamePrefix: functionNameSuffix,
    );
  }

  String url(String path);
}

class _FirebaseFunctionsTestClientContextBaseUrl
    implements FirebaseFunctionsTestClientContext {
  @override
  final HttpClientFactory httpClientFactory;
  @override
  final String baseUrl;
  @override
  FirebaseFunctionsCall? functionsCall;
  @override
  final String? functionNamePrefix;
  _FirebaseFunctionsTestClientContextBaseUrl({
    required this.httpClientFactory,
    required this.baseUrl,
    required this.functionsCall,
    this.functionNamePrefix,
  });

  String _fixName(String name) {
    if (functionNamePrefix != null) {
      return '$functionNamePrefix$name';
    }
    return name;
  }

  @override
  String url(String path) {
    return p.url.join(baseUrl, _fixName(path));
  }
}

mixin FirebaseFunctionsTestClientContextMixin
    implements FirebaseFunctionsTestClientContext {
  @override
  FirebaseFunctionsCall? get functionsCall => null;
}
