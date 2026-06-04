import 'package:path/path.dart' as p;
import 'package:tekartik_firebase_functions/ff_server.dart';
// ignore: depend_on_referenced_packages
import 'package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart';

/// HTTP test context implementation for Firebase Functions.
class FirebaseFunctionsTestContextHttp extends FirebaseFunctionsTestContext
    with
        FirebaseFunctionsTestClientContextMixin,
        FirebaseFunctionsTestServerContextHttpMixin,
        FirebaseFunctionsTestClientContextHttpMixin {
  /// Creates a new [FirebaseFunctionsTestContextHttp] instance.
  FirebaseFunctionsTestContextHttp({
    /// external client factory
    required super.httpClientFactory,
    required super.firebaseFunctions,
    super.baseUrl,
    super.functionsCall,
  });

  @override
  String url(String path) => baseUrl != null
      ? super.url(path)
      : p.url.join(server.uri.toString(), path);
}

/// Server context mixin for HTTP Firebase Functions tests.
mixin FirebaseFunctionsTestServerContextHttpMixin
    on FirebaseFunctionsTestServerContext {
  // To set when ready
  /// The running Firebase Functions server instance.
  late FfServer server;
  int? _port;

  /// Port used to serve
  int? get port => _port;

  /// Serve locally
  @override
  Future<FfServer> serve({int? port}) async {
    return server = await firebaseFunctions.serve(port: port);
  }
}

/// Client context mixin for HTTP Firebase Functions tests.
mixin FirebaseFunctionsTestClientContextHttpMixin
    on FirebaseFunctionsTestClientContext {
  String _fixName(String name) {
    if (functionNamePrefix != null) {
      return '$functionNamePrefix$name';
    }
    return name;
  }

  @override
  String url(String path) {
    path = _fixName(path);
    var baseUrl = this.baseUrl!;
    if (baseUrl.contains('{{function}}')) {
      var function = path.split('/').first.split('?').first.split('#').first;
      var remaining = path.substring(function.length);
      return p.url.join(
        baseUrl.replaceAll('{{function}}', function),
        remaining,
      );
    }
    return p.url.join(baseUrl, path);
  }
}

/// Server context implementation for HTTP Firebase Functions tests.
class FirebaseFunctionsTestServerContextHttp
    extends FirebaseFunctionsTestServerContext
    with FirebaseFunctionsTestServerContextHttpMixin {
  /// Creates a new [FirebaseFunctionsTestServerContextHttp] instance.
  FirebaseFunctionsTestServerContextHttp({
    /// external client factory
    required super.firebaseFunctions,
  });
}

/// Client context implementation for HTTP Firebase Functions tests.
class FirebaseFunctionsTestClientContextHttp
    extends FirebaseFunctionsTestClientContext
    with
        FirebaseFunctionsTestClientContextMixin,
        FirebaseFunctionsTestClientContextHttpMixin {
  /// Creates a new [FirebaseFunctionsTestClientContextHttp] instance.
  FirebaseFunctionsTestClientContextHttp({
    /// external client factory
    required super.httpClientFactory,
    required super.baseUrl,
    super.functionsCall,
    super.functionNamePrefix,
  });
}
