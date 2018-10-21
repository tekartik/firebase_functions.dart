import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tekartik_http/http.dart';

String requestBodyAsText(dynamic body) {
  if (body is String) {
    return body;
  } else if (body is List) {
    return utf8.decode(body?.cast<int>());
  }
  throw 'body $body not text';
}

Map<String, dynamic> requestBodyAsJsonObject(dynamic body) {
  if (body is Map) {
    return body?.cast<String, dynamic>();
  } else if (body is String) {
    return (json.decode(body) as Map)?.cast<String, dynamic>();
  } else if (body is List) {
    return requestBodyAsJsonObject(requestBodyAsText(body));
  }
  throw 'body $body not json object';
}

abstract class ExpressHttpRequest {
  // String, List<int>, Map
  dynamic get body;
  Uri get uri;
  HttpResponse get response;
  String get method;
  HttpHeaders get headers;

  @deprecated
  Uri get requestedUri;
}

abstract class ExpressHttpRequestWrapperBase extends Stream<List<int>>
    with HttpRequestWrapperMixin {
  final HttpRequest implHttpRequest;
  final Uri _rewrittenUri;

  ExpressHttpRequestWrapperBase(this.implHttpRequest, this._rewrittenUri);
}

abstract class HttpRequestWrapperMixin implements HttpRequest {
  HttpRequest get implHttpRequest;
  Uri get _rewrittenUri;

  @override
  HttpResponse get response => implHttpRequest.response;

  @override
  X509Certificate get certificate => implHttpRequest.certificate;

  @override
  HttpConnectionInfo get connectionInfo => implHttpRequest.connectionInfo;

  @override
  int get contentLength => implHttpRequest.contentLength;

  @override
  List<Cookie> get cookies => implHttpRequest.cookies;

  @override
  HttpHeaders get headers => implHttpRequest.headers;

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
  HttpSession get session => implHttpRequest.session;

  // The only one to use
  @override
  Uri get uri => _rewrittenUri;
}
