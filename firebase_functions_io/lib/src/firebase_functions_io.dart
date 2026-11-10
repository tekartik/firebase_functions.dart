import 'dart:io' as io;
import 'dart:typed_data';

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

  /// Set by [serve] to also serve the local files of this folder.
  String? _publicDir;

  @override
  Future onFileRequestHttp(HttpRequest request) {
    var publicDir = _publicDir;
    if (publicDir != null) {
      return onFileRequest(request, publicDir: publicDir);
    }
    return super.onFileRequestHttp(request);
  }
}

FirebaseFunctionsIo? _firebaseFunctionsIo;

final _firebaseFunctionsServiceIo = FirebaseFunctionsServiceIo();
FirebaseFunctionsIo get firebaseFunctionsIo => _firebaseFunctionsIo ??=
    FirebaseFunctionsIo._(_firebaseFunctionsServiceIo, newFirebaseAppLocal());

/// The local file of [publicDir] served for the request [uri]
/// (`index.html` for `/` and for a path ending with `/`), null for a path
/// that would leave [publicDir] (`..`, an encoded separator...).
String? publicDirFilePath(Uri uri, {String publicDir = 'public'}) {
  var segments = uri.pathSegments;
  var parts = <String>[];
  for (var i = 0; i < segments.length; i++) {
    var segment = segments[i];
    if (segment.isEmpty) {
      // Only a trailing / (a folder).
      if (i == segments.length - 1) {
        continue;
      }
      return null;
    }
    if (segment == '.' ||
        segment == '..' ||
        segment.contains('/') ||
        segment.contains(r'\') ||
        segment.contains(':')) {
      return null;
    }
    parts.add(segment);
  }
  if (parts.isEmpty || uri.path.endsWith('/')) {
    parts.add('index.html');
  }
  return [publicDir, ...parts].join(io.Platform.pathSeparator);
}

// TODO: etags, last-modified-since support
/// Serves the file of [publicDir] matching [request] (see
/// [publicDirFilePath]), 404 when there is none.
Future onFileRequest(HttpRequest request, {String publicDir = 'public'}) async {
  final path = publicDirFilePath(request.uri, publicDir: publicDir);
  final targetFile = path == null ? null : io.File(path);

  if (targetFile != null && targetFile.existsSync()) {
    Uint8List bytes;
    try {
      bytes = await targetFile.readAsBytes();
    } catch (e) {
      // ignore: avoid_print
      print("Couldn't read file: $e");
      request.response.statusCode = io.HttpStatus.forbidden;
      await request.response.close();
      return;
    }
    request.response.headers.contentType = ContentType.parse(
      httpContentTypeHtml,
    ); // ContentType.html;
    request.response.add(bytes);
    await request.response.close();
  } else {
    request.response.statusCode = io.HttpStatus.notFound;
    await request.response.close();
  }
}

// For io only
// To run the server in parallel
/// Serve [firebaseFunctionsIo] functions (like [FirebaseFunctionsHttp.serveHttp])
/// and the local files of [publicDir] for the other paths (only the files of
/// that folder: a path out of it is not found).
Future<HttpServer> serve({int? port, String publicDir = 'public'}) async {
  firebaseFunctionsIo._publicDir = publicDir;
  return await firebaseFunctionsIo.serveHttp(port: port ?? 4999);
}

/// The global memory service.
final firebaseFunctionsServiceIo = FirebaseFunctionsServiceIo();
