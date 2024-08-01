import 'dart:io' as io;

import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_functions_http/src/firebase_functions_http.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_functions_io/src/express_http_request_io.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_http_io/http_server_io.dart';

import 'import.dart';

/// Memory service.
class FirebaseFunctionsServiceIo
    with
        FirebaseProductServiceMixin<FirebaseFunctions>,
        FirebaseFunctionsServiceDefaultMixin
    implements FirebaseFunctionsServiceHttp {
  @override
  FirebaseFunctionsHttp functions(FirebaseApp app) => getInstance(app, () {
        return FirebaseFunctionsIo._(app);
      });
}

class FirebaseFunctionsIo extends FirebaseFunctionsHttpBase {
  FirebaseFunctionsIo._(FirebaseApp firebaseApp)
      : super(firebaseApp, httpServerFactoryIo);
}

FirebaseFunctionsIo? _firebaseFunctionsIo;

FirebaseFunctionsIo get firebaseFunctionsIo =>
    _firebaseFunctionsIo ??= FirebaseFunctionsIo._(newFirebaseAppLocal());

// TODO: etags, last-modified-since support
Future onFileRequest(HttpRequest request) async {
  final path = rewritePath(request.uri.path);
  final targetFile = io.File(path);

  if (targetFile.existsSync()) {
    print('Serving ${targetFile.path}.');
    request.response.headers.contentType =
        ContentType.parse(httpContentTypeHtml); // ContentType.html;
    try {
      await targetFile.openRead().cast<List<int>>().pipe(request.response);
    } catch (e) {
      print("Couldn't read file: $e");
      // exit(-1);
      request.response.statusCode = io.HttpStatus.forbidden;
      await request.response.close();
    }
  } else {
    print("Can't open ${targetFile.path}.");
    request.response.statusCode = io.HttpStatus.notFound;
    await request.response.close();
  }
}

// For io only
// To run the server in parallel
Future<HttpServer> serve({int? port}) async {
  port ??= 4999;
  var requestServer =
      await httpServerFactoryIo.bind(io.InternetAddress.anyIPv4, port);
  for (final key in firebaseFunctionsIo.functions.keys) {
    print('$key http://localhost:$port/$key');
  }

  print('listening on http://localhost:${requestServer.port}');
  var handled = false;
  // Launch in background
  unawaited(Future.sync(() async {
    await for (HttpRequest request in requestServer) {
      var uri = request.uri;
      // /test
      var functionKey = uri.pathSegments.first;
      var function = firebaseFunctionsIo.functions[functionKey];
      if (function is HttpsFunctionHttp) {
        final rewrittenUri = Uri(
            pathSegments: uri.pathSegments.sublist(1),
            query: uri.query,
            fragment: uri.fragment);
        //io.HttpRequest commonRequest = new io.HttpRequest(request, url, request.uri.path);
        ExpressHttpRequest httpRequest =
            await asExpressHttpRequestIo(request, rewrittenUri);
        function.handler(httpRequest);
        handled = true;
      }

      if (!handled) {
        await onFileRequest(request);
      }
    }
  }));
  return requestServer;
}

/// The global memory service.
final firebaseFunctionsServiceIo = FirebaseFunctionsServiceIo();
