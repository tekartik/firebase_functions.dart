import 'dart:io' as io;

import 'package:tekartik_firebase_functions_http/src/firebase_functions_http.dart'; // ignore: implementation_imports
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
    return FirebaseFunctionsIo._(this, app);
  });
}

class FirebaseFunctionsIo extends FirebaseFunctionsHttpBase {
  FirebaseFunctionsIo._(
    FirebaseFunctionsServiceHttp firebaseFunctionsService,
    FirebaseApp firebaseApp,
  ) : super(firebaseFunctionsService, firebaseApp, httpServerFactoryIo);

  /// Set by [serve] to also serve the local files (public/).
  var _serveFiles = false;

  @override
  Future onFileRequestHttp(HttpRequest request) {
    if (_serveFiles) {
      return onFileRequest(request);
    }
    return super.onFileRequestHttp(request);
  }
}

FirebaseFunctionsIo? _firebaseFunctionsIo;

final _firebaseFunctionsServiceIo = FirebaseFunctionsServiceIo();
FirebaseFunctionsIo get firebaseFunctionsIo => _firebaseFunctionsIo ??=
    FirebaseFunctionsIo._(_firebaseFunctionsServiceIo, newFirebaseAppLocal());

// TODO: etags, last-modified-since support
Future onFileRequest(HttpRequest request) async {
  final path = rewritePath(request.uri.path);
  final targetFile = io.File(path);

  if (targetFile.existsSync()) {
    // print('Serving ${targetFile.path}.');
    request.response.headers.contentType = ContentType.parse(
      httpContentTypeHtml,
    ); // ContentType.html;
    try {
      await targetFile.openRead().cast<List<int>>().pipe(request.response);
    } catch (e) {
      // ignore: avoid_print
      print("Couldn't read file: $e");
      // exit(-1);
      request.response.statusCode = io.HttpStatus.forbidden;
      await request.response.close();
    }
  } else {
    // ignore: avoid_print
    print("Can't open ${targetFile.path}.");
    request.response.statusCode = io.HttpStatus.notFound;
    await request.response.close();
  }
}

// For io only
// To run the server in parallel
/// Serve [firebaseFunctionsIo] functions (like [FirebaseFunctionsHttp.serveHttp])
/// and the local files (public/) for the other paths.
Future<HttpServer> serve({int? port}) async {
  firebaseFunctionsIo._serveFiles = true;
  return await firebaseFunctionsIo.serveHttp(port: port ?? 4999);
}

/// The global memory service.
final firebaseFunctionsServiceIo = FirebaseFunctionsServiceIo();
