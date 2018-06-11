import 'dart:async';
import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:path/path.dart' as path;
import 'package:tekartik_firebase_functions/firebase_functions.dart';

class FirebaseFunctionsIo implements FirebaseFunctions {
  Map<String, dynamic> functions = {};

  FirebaseFunctionsIo._();

  HttpsIo _https;
  @override
  HttpsIo get https => _https ??= new HttpsIo();

  operator []=(String key, dynamic function) {
    functions[key] = function;
  }
}

class HttpsIo implements Https {
  HttpsIo() {}

  @override
  HttpsFunction onRequest(RequestHandler handler) {
    return new HttpsFunctionIo(handler);
  }
}

class HttpsFunctionIo implements HttpsFunction {
  // ignore: unused_field
  final RequestHandler handler;

  HttpsFunctionIo(this.handler);
}

class IoHttpRequest extends Stream<List<int>> implements io.HttpRequest {
  final io.HttpRequest _implHttpRequest;

  final Uri rewrittenUri;

  IoHttpRequest(this._implHttpRequest, this.rewrittenUri);

  @override
  io.HttpResponse get response => _implHttpRequest.response;

  @override
  io.X509Certificate get certificate => _implHttpRequest.certificate;

  @override
  io.HttpConnectionInfo get connectionInfo => _implHttpRequest.connectionInfo;

  @override
  int get contentLength => _implHttpRequest.contentLength;

  @override
  List<io.Cookie> get cookies => _implHttpRequest.cookies;

  @override
  io.HttpHeaders get headers => _implHttpRequest.headers;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event) onData,
          {Function onError, void Function() onDone, bool cancelOnError}) =>
      _implHttpRequest.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  String get method => _implHttpRequest.method;

  @override
  bool get persistentConnection => _implHttpRequest.persistentConnection;

  @override
  String get protocolVersion => _implHttpRequest.protocolVersion;

  @override
  Uri get requestedUri => _implHttpRequest.requestedUri;

  @override
  io.HttpSession get session => _implHttpRequest.session;

  // The only one to use
  @override
  Uri get uri => rewrittenUri;
}

FirebaseFunctionsIo _firebaseFunctionsIo;

FirebaseFunctionsIo get firebaseFunctionsIo =>
    _firebaseFunctionsIo ??= new FirebaseFunctionsIo._();

// TODO: etags, last-modified-since support
onFileRequest(io.HttpRequest request) async {
  String path = rewritePath(request.uri.path);
  io.File targetFile = new io.File(path);
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
    request.response.headers.contentType = io.ContentType.HTML;
    try {
      await targetFile.openRead().pipe(request.response);
    } catch (e) {
      print("Couldn't read file: $e");
      // exit(-1);
      request.response
        ..statusCode = io.HttpStatus.FORBIDDEN
        ..close();
    }
  } else {
    print("Can't open ${targetFile.path}.");
    request.response
      ..statusCode = io.HttpStatus.NOT_FOUND
      ..close();
  }
}

// For io only
// To run the server in parallel
serve({int port}) async {
  port ??= 4999;
  var requestServer =
      await io.HttpServer.bind(io.InternetAddress.anyIPv4, port);
  for (String key in firebaseFunctionsIo.functions.keys) {
    print("$key http://localhost:${port}/${key}");
  }

  print('listening on http://localhost:${requestServer.port}');
  bool handled = false;
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
        IoHttpRequest ioHttpRequest = new IoHttpRequest(request, rewrittenUri);
        function.handler(ioHttpRequest);
        handled = true;
      }
    }
    if (!handled) {
      await onFileRequest(request);
    }
  }
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
