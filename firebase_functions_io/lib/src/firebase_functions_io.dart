import 'dart:async';
import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_io/src/express_http_request_io.dart';
import 'package:tekartik_http/http.dart';
import 'package:tekartik_http_io/http_server_io.dart';

class FirebaseFunctionsIo implements FirebaseFunctions {
  Map<String, dynamic> functions = {};

  FirebaseFunctionsIo._();

  HttpsIo _https;

  @override
  HttpsIo get https => _https ??= HttpsIo();

  @override
  operator []=(String key, dynamic function) {
    functions[key] = function;
  }
}

class HttpsIo implements Https {
  HttpsIo();

  @override
  HttpsFunction onRequest(RequestHandler handler) {
    return HttpsFunctionIo(handler);
  }
}

class HttpsFunctionIo implements HttpsFunction {
  // ignore: unused_field
  final RequestHandler handler;

  HttpsFunctionIo(this.handler);
}

/*
class IoHttpRequest extends Stream<List<int>> implements io.HttpRequest {
  final io.HttpRequest implHttpRequest;

  final Uri rewrittenUri;

  IoHttpRequest(this.implHttpRequest, this.rewrittenUri);

  @override
  io.HttpResponse get response => implHttpRequest.response;

  @override
  io.X509Certificate get certificate => implHttpRequest.certificate;

  @override
  io.HttpConnectionInfo get connectionInfo => implHttpRequest.connectionInfo;

  @override
  int get contentLength => implHttpRequest.contentLength;

  @override
  List<io.Cookie> get cookies => implHttpRequest.cookies;

  @override
  io.HttpHeaders get headers => implHttpRequest.headers;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event) onData,
          {Function onError, void Function() onDone, bool cancelOnError}) =>
      implHttpRequest.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  String get method => implHttpRequest.method;

  @override
  bool get persistentConnection => implHttpRequest.persistentConnection;

  @override
  String get protocolVersion => implHttpRequest.protocolVersion;

  @override
  Uri get requestedUri => implHttpRequest.requestedUri;

  @override
  io.HttpSession get session => implHttpRequest.session;

  // The only one to use
  @override
  Uri get uri => rewrittenUri;
}
*/
FirebaseFunctionsIo _firebaseFunctionsIo;

FirebaseFunctionsIo get firebaseFunctionsIo =>
    _firebaseFunctionsIo ??= FirebaseFunctionsIo._();

// TODO: etags, last-modified-since support
Future onFileRequest(HttpRequest request) async {
  String path = rewritePath(request.uri.path);
  io.File targetFile = io.File(path);
  /*
  final io.File file = new io.File('${path}');
  file.exists().then((found) {
    if (found) {
      file.fullPath().then((String fullPath) {
        if (!fullPath.startsWith(basePath)) {
          _send404(response);
        } else {
          file.openInputStream().pipe(response.outputStream);
        }
      });
    } else {
      _send404(response);
    }
  });
  */
  if (targetFile.existsSync()) {
    print("Serving ${targetFile.path}.");
    request.response.headers.contentType =
        ContentType.parse(httpContentTypeHtml); // ContentType.html;
    try {
      await targetFile.openRead().cast<List<int>>().pipe(request.response);
    } catch (e) {
      print("Couldn't read file: $e");
      // exit(-1);
      request.response..statusCode = io.HttpStatus.forbidden;
      await request.response.close();
    }
  } else {
    print("Can't open ${targetFile.path}.");
    request.response..statusCode = io.HttpStatus.notFound;
    await request.response.close();
  }
}

// For io only
// To run the server in parallel
Future<HttpServer> serve({int port}) async {
  port ??= 4999;
  var requestServer =
      await httpServerFactoryIo.bind(io.InternetAddress.anyIPv4, port);
  for (String key in firebaseFunctionsIo.functions.keys) {
    print("$key http://localhost:${port}/${key}");
  }

  print('listening on http://localhost:${requestServer.port}');
  bool handled = false;
  // Launch in background
  unawaited(Future.sync(() async {
    await for (HttpRequest request in requestServer) {
      var uri = request.uri;
      // /test
      var functionKey = uri.pathSegments.first;
      var function = firebaseFunctionsIo.functions[functionKey];
      if (function is HttpsFunctionIo) {
        Uri rewrittenUri = Uri(
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

String rewritePath(String path) {
  String newPath = path;

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
