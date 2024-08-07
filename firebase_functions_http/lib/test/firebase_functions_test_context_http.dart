import 'package:path/path.dart' as p;
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart'; // ignore: depend_on_referenced_packages

import '../ff_server.dart';
import '../firebase_functions_memory.dart';
import '../src/import.dart';

class FirebaseFunctionsTestContextHttp extends FirebaseFunctionsTestContext
    with
        FirebaseFunctionsTestServerContextHttpMixin,
        FirebaseFunctionsTestClientContextHttpMixin {
  FirebaseFunctionsTestContextHttp(
      {
      /// external client factory
      required super.httpClientFactory,
      required super.firebaseFunctions,
      super.baseUrl});

  @override
  String url(String path) => baseUrl != null
      ? super.url(path)
      : p.url.join(server.uri.toString(), path);
}

mixin FirebaseFunctionsTestServerContextHttpMixin
    on FirebaseFunctionsTestServerContext {
  // To set when ready
  late FfServer server;

  /// Serve locally
  @override
  Future<FfServer> serve() async {
    var server =
        await (firebaseFunctions as FirebaseFunctionsHttp).serveHttp(port: 0);
    return this.server = FfServerHttp(server);
  }
}
mixin FirebaseFunctionsTestClientContextHttpMixin
    on FirebaseFunctionsTestClientContext {
  @override
  String url(String path) {
    var baseUrl = this.baseUrl!;
    if (baseUrl.contains('{{function}}')) {
      var function = path.split('/').first.split('?').first.split('#').first;
      var remaining = path.substring(function.length);
      return p.url
          .join(baseUrl.replaceAll('{{function}}', function), remaining);
    }
    return p.url.join(baseUrl, path);
  }
}

class FirebaseFunctionsTestServerContextHttp
    extends FirebaseFunctionsTestServerContext
    with FirebaseFunctionsTestServerContextHttpMixin {
  FirebaseFunctionsTestServerContextHttp({
    /// external client factory
    required super.firebaseFunctions,
  });
}

class FirebaseFunctionsTestClientContextHttp
    extends FirebaseFunctionsTestClientContext
    with FirebaseFunctionsTestClientContextHttpMixin {
  FirebaseFunctionsTestClientContextHttp({
    /// external client factory
    required super.httpClientFactory,
    required super.baseUrl,
  });
}
