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
  final FirebaseFunctionsCall? functionsCall;
  final String? functionNamePrefix;

  FirebaseFunctionsTestClientContext({
    required this.httpClientFactory,
    this.baseUrl,
    this.functionNamePrefix,
    this.functionsCall,
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
  factory FirebaseFunctionsTestClientContext.urlTemplate({
    required HttpClientFactory httpClientFactory,
    required String urlTemplate,
    FirebaseFunctionsCall? functionsCall,
  }) {
    return _FirebaseFunctionsTestClientContextUrlTemplate(
      httpClientFactory: httpClientFactory,
      urlTemplate: urlTemplate,
      functionsCall: functionsCall,
    );
  }

  String url(String path);

  Future<void> close();
}

class _FirebaseFunctionsTestClientContextBaseUrl
    with FirebaseFunctionsTestClientContextMixin
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

class _FirebaseFunctionsTestClientContextUrlTemplate
    with FirebaseFunctionsTestClientContextMixin
    implements FirebaseFunctionsTestClientContext {
  @override
  final HttpClientFactory httpClientFactory;

  final String urlTemplate;
  @override
  FirebaseFunctionsCall? functionsCall;

  _FirebaseFunctionsTestClientContextUrlTemplate({
    required this.httpClientFactory,
    required this.urlTemplate,
    required this.functionsCall,
  });

  @override
  String url(String path) {
    return urlTemplate
        .replaceAll('{{function}}', path)
        .replaceAll('__function__', path);
  }

  @override
  String? get baseUrl => throw UnimplementedError();

  @override
  String? get functionNamePrefix => throw UnimplementedError();
}

mixin FirebaseFunctionsTestClientContextMixin
    implements FirebaseFunctionsTestClientContext {
  @override
  FirebaseFunctionsCall? get functionsCall => null;

  @override
  Future<void> close() async {}
}
