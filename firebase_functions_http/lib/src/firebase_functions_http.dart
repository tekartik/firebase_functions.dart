import 'package:cv/cv_json.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions/utils.dart';
import 'package:tekartik_firebase_functions_http/ff_server.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
import 'package:tekartik_firebase_functions_http/src/firestore_functions_firestore_http.dart';

import 'express_http_request_http.dart';
import 'import.dart';

/// Http service definition.
abstract class FirebaseFunctionsServiceHttp
    implements FirebaseFunctionsService {
  @override
  FirebaseFunctionsHttp functions(FirebaseApp app);
}

/// Default mixin for [FirebaseFunctionsHttp].
mixin FirebaseFunctionsHttpDefaultMixin implements FirebaseFunctionsHttp {
  @override
  void init({Firestore? firestore}) {
    throw UnimplementedError('init');
  }

  @override
  Future<FfServer> serve({int? port}) async {
    var server = await serveHttp(port: port);
    return FfServerHttp(server);
  }

  // For io only
  // To run the server in parallel
  /// To implement
  @override
  Future<HttpServer> serveHttp({int? port}) async =>
      throw UnimplementedError('serveHttp');

  @override
  Future onFileRequestHttp(HttpRequest request) {
    throw UnsupportedError('io required for onFileRequest');
  }
}

/// Base class for HTTP Firebase functions.
class FirebaseFunctionsHttpBase
    with
        FirebaseAppProductMixin<FirebaseFunctions>,
        FirebaseFunctionsDefaultMixin,
        FirebaseFunctionsHttpDefaultMixin
    implements FirebaseFunctionsHttp {
  /// The associated HTTP Firebase Functions service.
  final FirebaseFunctionsServiceHttp firebaseFunctionsServiceHttp;

  @override
  FirebaseApp get app => firebaseApp;

  /// The associated [FirebaseApp] instance.
  final FirebaseApp firebaseApp;

  /// The HTTP server factory to bind servers.
  HttpServerFactory httpServerFactory;

  /// Optional global options.
  GlobalOptions? globalOptions;

  /// Creates a new [FirebaseFunctionsHttpBase] instance.
  FirebaseFunctionsHttpBase(
    this.firebaseFunctionsServiceHttp,
    this.firebaseApp,
    this.httpServerFactory,
  ) : super();

  @override
  late final https = HttpsHttp();

  @override
  void init({Firestore? firestore}) {
    firebaseFirestore = firestore;
  }

  /// The Firestore instance, if initialized.
  Firestore? firebaseFirestore;

  /// Returns the Firestore instance or throws a StateError if not initialized.
  Firestore get firebaseFirestoreOrThrow {
    var firestore = firebaseFirestore;
    if (firestore != null) {
      return firestore;
    }
    throw StateError(
      'Firestore instance not initialized in function, call functions.init(firestore: firestore) first',
    );
  }

  @override
  late final firestore = FirestoreFunctionsHttp(this);

  /// The registered functions map.
  Map<String, Object?> functions = {};

  @override
  operator []=(String key, FirebaseFunction function) {
    functions[key] = function;
  }

  @override
  void registerFunction(String name, FirebaseFunction function) {
    functions[name] = function;
  }

  @override
  Future<HttpServer> serveHttp({int? port}) async {
    port ??= firebaseFunctionsHttpDefaultPort;
    var requestServer = await httpServerFactory.bind(
      InternetAddress.anyIPv4,
      port,
    );
    for (final key in functions.keys) {
      // ignore: avoid_print
      print('$key http://localhost:$port/$key');
    }

    // ignore: avoid_print
    print('listening on http://localhost:${requestServer.port}');

    // Launch in background
    unawaited(
      Future.sync(() async {
        await for (HttpRequest request in requestServer) {
          var uri = request.uri;
          var handled = false;
          // /test
          var functionKey = listFirst(uri.pathSegments);
          if (functionKey == null) {
            // ignore: avoid_print
            print('No functions key found for $uri');
          } else {
            var function = functions[functionKey];
            if (function is HttpsFunctionHttp) {
              final rewrittenUri = Uri(
                pathSegments: uri.pathSegments.sublist(1),
                query: uri.query,
                fragment: uri.fragment,
              );
              //io.HttpRequest commonRequest = new io.HttpRequest(request, url, request.uri.path);
              ExpressHttpRequest httpRequest = await asExpressHttpRequestHttp(
                request,
                rewrittenUri,
              );
              // cors?
              var cors = function.options?.cors ?? false;
              if (cors) {
                httpRequest.response.headers
                  ..set('Access-Control-Allow-Origin', '*')
                  ..set('Access-Control-Allow-Methods', 'POST, OPTIONS, GET');
                var requestHeaders =
                    request.headers['Access-Control-Request-Headers'];
                if (requestHeaders != null) {
                  httpRequest.response.headers.set(
                    'Access-Control-Allow-Headers',
                    requestHeaders,
                  );
                }
              }

              function.handler(httpRequest);
              handled = true;
            }
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
      }),
    );
    return requestServer;
  }

  /// No-op.
  @Deprecated('use setGlobalOptions')
  @override
  FirebaseFunctions region(String region) => this;

  /// No-op.
  @override
  @Deprecated('use setGlobalOptions')
  FirebaseFunctions runWith(RuntimeOptions options) => this;

  @override
  late final params = ParamsHttp(this);

  @override
  FirebaseFunctionsService get service => firebaseFunctionsServiceHttp;
}

/// Parameters implementation for HTTP Firebase functions.
class ParamsHttp extends Params {
  /// The associated Firebase functions instance.
  final FirebaseFunctionsHttpBase functions;

  /// Creates a new [ParamsHttp] instance.
  ParamsHttp(this.functions);

  @override
  String get projectId {
    var projectId = functions.firebaseApp.options.projectId;
    if (projectId != null) {
      return projectId;
    }
    throw StateError('Define a default projectId for the memory functions');
  }
}

/// Interface for HTTP Firebase functions.
abstract class FirebaseFunctionsHttp implements FirebaseFunctions {
  /// Initializes the functions environment.
  void init({Firestore? firestore});

  /// To implement
  Future<HttpServer> serveHttp({int? port});

  /// Handles serving local files over HTTP.
  Future onFileRequestHttp(HttpRequest request);
}

/// HTTPS functions implementation for HTTP Firebase functions.
class HttpsHttp with HttpsFunctionsDefaultMixin implements HttpsFunctions {
  /// Creates a new [HttpsHttp] instance.
  HttpsHttp();

  @override
  HttpsFunction onRequest(
    RequestHandler handler, {
    HttpsOptions? httpsOptions,
  }) {
    return HttpsFunctionHttp(httpsOptions, handler);
  }

  @override
  HttpsFunction onRequestV2(HttpsOptions httpsOptions, RequestHandler handler) {
    return HttpsFunctionHttp(httpsOptions, handler);
  }

  @override
  HttpsCallableFunction onCall(
    CallHandler handler, {
    HttpsCallableOptions? callableOptions,
  }) {
    return HttpsCallableFunctionHttp(callableOptions, handler);
  }
}

/// HTTPS function HTTP implementation interface.
abstract class HttpsFunctionHttp implements HttpsFunction {
  /// Optional HTTPS options.
  HttpsOptions? get options;

  // ignore: unused_field
  /// The request handler.
  RequestHandler get handler;

  /// Creates a new [HttpsFunctionHttp] instance.
  factory HttpsFunctionHttp(HttpsOptions? options, RequestHandler handler) =>
      _HttpsFunctionImpl(options, handler);
}

class _HttpsFunctionImpl extends _HttpsFunctionBase
    implements HttpsFunctionHttp {
  _HttpsFunctionImpl(super.options, super.handler);
}

abstract class _HttpsFunctionBase implements HttpsFunction {
  final HttpsOptions? options;

  // ignore: unused_field
  final RequestHandler handler;

  _HttpsFunctionBase(this.options, this.handler);
}

/// HTTPS callable function HTTP implementation interface.
abstract class HttpsCallableFunctionHttp
    implements HttpsCallableFunction, HttpsFunctionHttp {
  /// Optional HTTPS callable options.
  HttpsCallableOptions? get callableOptions;

  // ignore: unused_field
  /// The call handler.
  CallHandler get callHandler;

  /// Creates a new [HttpsCallableFunctionHttp] instance.
  factory HttpsCallableFunctionHttp(
    HttpsCallableOptions? callableOptions,
    CallHandler callHandler,
  ) => HttpsCallableFunctionHttpImpl(callableOptions, callHandler);
}

/// Implementation of [HttpsCallableFunctionHttp].
class HttpsCallableFunctionHttpImpl extends _HttpsFunctionBase
    implements HttpsCallableFunctionHttp {
  @override
  final HttpsCallableOptions? callableOptions;

  // ignore: unused_field
  @override
  final CallHandler callHandler;

  /// Creates a new [HttpsCallableFunctionHttpImpl] instance.
  HttpsCallableFunctionHttpImpl(this.callableOptions, this.callHandler)
    : super(callableOptions, (ExpressHttpRequest request) async {
        Future<void> sendError(
          ExpressHttpResponse response,
          HttpsError e,
        ) async {
          try {
            response.statusCode = httpsErrorCodeToStatusCode(e.code);
            response.headers.set(httpHeaderContentType, httpContentTypeJson);
          } catch (_) {
            // ignore: avoid_print
            print('error setting status code');
          }
          await response.send(jsonEncode({'error': e.toHttpJson()}));
        }

        try {
          var contentType = request.headers.contentType?.toString();
          if (!(contentType?.toString().contains('application/json') ??
              false)) {
            throw HttpsError(
              HttpsErrorCode.invalidArgument,
              'Request has incorrect Content-Type. $contentType',
              null,
            );
          }
          var result = await callHandler(CallRequestHttp(request));
          var response = request.response;
          response.headers.set(httpHeaderContentType, httpContentTypeJson);
          var reponseString = {'result': result}.cvToJson();
          await response.send(reponseString);
        } on HttpsError catch (e) {
          var response = request.response;

          await sendError(response, e);
        } catch (e) {
          var httpsError = HttpsError(
            HttpsErrorCode.internal,
            'Internal error',
            {'exception': '$e'},
          );
          var response = request.response;
          await sendError(response, httpsError);
        }
      });
}

/// Rewrites a URL path for serving local files.
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
  // ignore: avoid_print
  print('$path -> $newPath');

  return newPath;
}
