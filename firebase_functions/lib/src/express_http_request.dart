import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tekartik_http/http.dart';
import 'package:tekartik_http/src/utils.dart'; // ignore: implementation_imports

String requestBodyAsText(dynamic body) {
  if (body is String) {
    return body;
  } else if (body is Uint8List) {
    return utf8.decode(body.cast<int>());
  } else if (body is Map) {
    return jsonEncode(body);
  } else if (body is List) {
    return jsonEncode(body);
  }
  throw 'body $body not text';
}

Map<String, Object?>? requestBodyAsJsonObject(dynamic body) {
  if (body == null) {
    return null;
  } else if (body is Map) {
    return body.cast<String, Object?>();
  } else if (body is String) {
    try {
      return (json.decode(body) as Map?)?.cast<String, Object?>();
    } catch (_) {
      return null;
    }
  } else if (body is List) {
    return requestBodyAsJsonObject(requestBodyAsText(body));
  }
  throw 'body $body not json object';
}

abstract class ExpressHttpRequest {
  // String, List<int>, Map
  Object? get body;

  Uri get uri;

  ExpressHttpResponse get response;

  String get method;

  HttpHeaders get headers;

  @Deprecated('Use uri')
  Uri get requestedUri;
}

/// Extension to get the body as a map
extension ExpressHttpRequestExt on ExpressHttpRequest {
  /// Get the body as a map
  Map<String, Object?> get bodyAsMap => bodyAsMapOrNull!;

  /// Get the body as a text
  Map<String, Object?>? get bodyAsMapOrNull => httpDataAsMapOrNull(body);

  /// Get the body as a text - DEPRECATED
  String? get bodyAsText => requestBodyAsText(body);

  /// Get the body as a text
  String get bodyAsString => httpDataAsString(body!);
}

abstract class ExpressHttpResponse {
  /// send closes too
  /// Node only supports this.
  Future send([Object? body]);

  // redirect
  Future redirect(Uri location, {int? status});

  // Write a string
  void write(String content);

  void writeln(String content);

  // Add bytes
  void add(Uint8List bytes);

  // get and set status code
  int get statusCode;

  set statusCode(int statusCode);

  /// To call if not using send
  Future close();

  HttpHeaders get headers;
}

abstract class ExpressHttpRequestWrapperBase extends Object
    with HttpRequestWrapperMixin {
  @override
  final HttpRequest implHttpRequest;
  @override
  final Uri _rewrittenUri;

  ExpressHttpRequestWrapperBase(this.implHttpRequest, this._rewrittenUri);
}

abstract class ExpressHttpResponseWrapperBase extends Object
    with HttpResponseWrapperMixin {
  ExpressHttpResponseWrapperBase(HttpResponse implHttpResponse) {
    this.implHttpResponse = implHttpResponse;
  }
}

abstract mixin class HttpResponseWrapperMixin implements ExpressHttpResponse {
  late HttpResponse implHttpResponse;

  @override
  Future send([Object? body]) {
    if (body != null) {
      if (body is Uint8List) {
        implHttpResponse.add(body);
      } else if (body is String) {
        implHttpResponse.write(body);
      } else if (body is List<int>) {
        implHttpResponse.add(asUint8List(body));
      } else if (body is Map || body is List) {
        implHttpResponse.write(jsonEncode(body));
      } else {
        throw '${body.runtimeType} not supported';
      }
    }
    return implHttpResponse.close();
  }

  // status code
  @override
  int get statusCode => implHttpResponse.statusCode;

  @override
  set statusCode(int statusCode) => implHttpResponse.statusCode = statusCode;

  @override
  HttpHeaders get headers => implHttpResponse.headers;

  @override
  void add(Uint8List bytes) => implHttpResponse.add(bytes);

  @override
  Future close() => implHttpResponse.close();

  @override
  void write(String content) => implHttpResponse.write(content);

  @override
  void writeln(String content) => implHttpResponse.write(content);

  @override
  Future redirect(Uri location, {int? status}) => implHttpResponse.redirect(
    location,
    status: status ?? httpStatusMovedTemporarily,
  );

  /*
  @override
  Future redirect(Uri location, {int status}) {
    statusCode = status;
    headers.set("location", "$location");
    return close();
  }
   */
}

abstract mixin class HttpRequestWrapperMixin implements ExpressHttpRequest {
  HttpRequest get implHttpRequest;

  Uri get _rewrittenUri;

  @override
  HttpHeaders get headers => implHttpRequest.headers;

  @override
  String get method => implHttpRequest.method;

  @override
  Uri get requestedUri => implHttpRequest.requestedUri;

  // The only one to use
  @override
  Uri get uri => _rewrittenUri;
}
