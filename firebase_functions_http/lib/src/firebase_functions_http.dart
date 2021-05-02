import 'dart:async';

import 'package:path/path.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tekartik_common_utils/list_utils.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_http/http.dart';

import 'express_http_request_http.dart';

class FirebaseFunctionsHttpBase extends FirebaseFunctionsHttp {
  HttpServerFactory httpServerFactory;

  FirebaseFunctionsHttpBase(this.httpServerFactory) : super();

  Map<String, dynamic> functions = {};

  @override
  operator []=(String key, FirebaseFunction function) {
    functions[key] = function;
  }

  @override
  Future<HttpServer> serveHttp({int? port}) async {
    port ??= 4999;
    var requestServer =
        await httpServerFactory.bind(InternetAddress.anyIPv4, port);
    for (final key in functions.keys) {
      print('$key http://localhost:$port/$key');
    }

    print('listening on http://localhost:${requestServer.port}');
    var handled = false;
    // Launch in background
    unawaited(Future.sync(() async {
      await for (HttpRequest request in requestServer) {
        var uri = request.uri;
        // /test
        var functionKey = listFirst(uri.pathSegments);
        var function = functions[functionKey!];
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
}

abstract class FirebaseFunctionsHttp implements FirebaseFunctions {
  FirebaseFunctionsHttp();

  HttpsFunctions? _https;

  @override
  HttpsFunctions get https => _https ??= HttpsHttp();

  @override
  FirestoreFunctions get firestore => throw UnimplementedError();

  @override
  PubsubFunctions get pubsub => throw UnimplementedError();

// For io only
// To run the server in parallel
  /// To implement
  Future<HttpServer?> serveHttp({int? port}) async => null;

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

class HttpsHttp with HttpsFunctionsMixin implements HttpsFunctions {
  HttpsHttp();

  @override
  HttpsFunction onRequest(RequestHandler handler) {
    return HttpsFunctionHttp(handler);
  }

  @override
  CallFunction onCall(CallHandler handler) {
    return CallFunctionHttp(handler);
  }
}

class HttpsFunctionHttp implements HttpsFunction {
  // ignore: unused_field
  final RequestHandler handler;

  HttpsFunctionHttp(this.handler);
}

class CallFunctionHttp implements CallFunction {
  // ignore: unused_field
  final CallHandler handler;

  CallFunctionHttp(this.handler);
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
