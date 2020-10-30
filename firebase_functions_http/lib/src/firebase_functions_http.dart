import 'dart:async';

import 'package:path/path.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_http/http.dart';
import 'package:tekartik_common_utils/list_utils.dart';
import 'express_http_request_http.dart';

class FirebaseFunctionsHttp implements FirebaseFunctions {
  final HttpServerFactory httpServerFactory;
  Map<String, dynamic> functions = {};

  FirebaseFunctionsHttp(this.httpServerFactory);

  HttpsFunctions _https;

  @override
  HttpsFunctions get https => _https ??= HttpsHttp();

  @override
  operator []=(String key, dynamic function) {
    functions[key] = function;
  }

  @override
  FirestoreFunctions get firestore => throw UnimplementedError();

  @override
  PubsubFunctions get pubsub => throw UnimplementedError();

// For io only
// To run the server in parallel
  Future<HttpServer> serveHttp({int port}) async {
    port ??= 4999;
    var requestServer =
        await httpServerFactory.bind(InternetAddress.anyIPv4, port);
    for (final key in functions.keys) {
      print('$key http://localhost:${port}/${key}');
    }

    print('listening on http://localhost:${requestServer.port}');
    var handled = false;
    // Launch in background
    unawaited(Future.sync(() async {
      await for (HttpRequest request in requestServer) {
        var uri = request.uri;
        // /test
        var functionKey = listFirst(uri.pathSegments);
        var function = functions[functionKey];
        if (function is HttpsFunctionHttp) {
          final rewrittenUri = Uri(
              pathSegments: uri.pathSegments.sublist(1),
              query: uri.query,
              fragment: uri.fragment);
          //io.HttpRequest commonRequest = new io.HttpRequest(request, url, request.uri.path);
          ExpressHttpRequest httpRequest =
              await asExpressHttpRequestHttp(request, rewrittenUri);
          function.handler(httpRequest);
          handled = true;
        }

        if (!handled) {
          try {
            await onFileRequestHttp(request);
          } catch (e) {
            request.response.statusCode = httpStatusCodeNotFound;
            await request.response.close();
          }
        }
      }
    }));
    return requestServer;
  }

  Future onFileRequestHttp(HttpRequest request) {
    throw UnsupportedError('io required for onFileRequest');
  }

  /// No-op.
  @override
  FirebaseFunctions region(String region) => this;

  /// No-op.
  @override
  FirebaseFunctions runWith(RuntimeOptions options) => this;
}

class HttpsHttp implements HttpsFunctions {
  HttpsHttp();

  @override
  HttpsFunction onRequest(RequestHandler handler) {
    return HttpsFunctionHttp(handler);
  }
}

class HttpsFunctionHttp implements HttpsFunction {
  // ignore: unused_field
  final RequestHandler handler;

  HttpsFunctionHttp(this.handler);
}

String rewritePath(String path) {
  var newPath = path;

  if (path == '/') {
    newPath = url.join('public', 'index.html');
  } else if (path.endsWith('/')) {
    newPath = url.join('public', path, 'index.html');
  } else if (!path.endsWith('.html')) {
    /*
    if (path.contains('.')) {
      newPath = '/web${path}';
    } else {
      newPath = '/web${path}.html';
    }
    */
  } else {
    newPath = url.join('public', path);
  }

  //peek into how it's rewriting the paths
  print('$path -> $newPath');

  return newPath;
}
