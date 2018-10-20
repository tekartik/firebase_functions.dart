import 'dart:async';
import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:path/path.dart' as path;
import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_io/src/express_http_request_io.dart';

class FirebaseFunctionsIo implements FirebaseFunctions {
  Map<String, dynamic> functions = {};

  FirebaseFunctionsIo._();

  HttpsIo _https;
  @override
  HttpsIo get https => _https ??= HttpsIo();

  operator []=(String key, dynamic function) {
    functions[key] = function;
  }
}

class HttpsIo implements Https {
  HttpsIo() {}

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
onFileRequest(io.HttpRequest request) async {
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
  if (await targetFile.exists()) {
    print("Serving ${targetFile.path}.");
    request.response.headers.contentType = io.ContentType.html;
    try {
      await targetFile.openRead().pipe(request.response);
    } catch (e) {
      print("Couldn't read file: $e");
      // exit(-1);
      request.response
        ..statusCode = io.HttpStatus.forbidden
        ..close();
    }
  } else {
    print("Can't open ${targetFile.path}.");
    request.response
      ..statusCode = io.HttpStatus.notFound
      ..close();
  }
}

// For io only
// To run the server in parallel
Future<HttpServer> serve({int port}) async {
  port ??= 4999;
  var requestServer =
      await io.HttpServer.bind(io.InternetAddress.anyIPv4, port);
  for (String key in firebaseFunctionsIo.functions.keys) {
    print("$key http://localhost:${port}/${key}");
  }

  print('listening on http://localhost:${requestServer.port}');
  bool handled = false;
  // Launch in background
  Future.sync(() async {
    await for (io.HttpRequest request in requestServer) {
      //devPrint(request.uri.path);
      // /test
      List<String> parts = url.split(request.uri.toString());
      if (parts.length > 1) {
        String key = parts[1]; // 0 being /
        var function = firebaseFunctionsIo.functions[key];
        if (function is HttpsFunctionIo) {
          Uri rewrittenUri =
              Uri.parse(path.url.join('/', path.url.joinAll(parts.sublist(2))));
          //io.HttpRequest commonRequest = new io.HttpRequest(request, url, request.uri.path);
          ExpressHttpRequest httpRequest =
              await asExpressHttpRequestIo(request, rewrittenUri);
          function.handler(httpRequest);
          handled = true;
        }
      }
      if (!handled) {
        await onFileRequest(request);
      }
    }
  });
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
