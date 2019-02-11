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
  ExpressHttpResponse get response;
  String get method;
  HttpHeaders get headers;

  @deprecated
  Uri get requestedUri;
}

abstract class ExpressHttpResponse {
  // send closes too
  Future send([dynamic body]);

  // redirect
  Future redirect(Uri location, {int status});

  // Write a string
  void write(String content);
  void writeln(String content);

  // Add bytes
  void add(List<int> bytes);

  // get and set status code
  int get statusCode;
  set statusCode(int statusCode);

  // To call if not using call
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

abstract class HttpResponseWrapperMixin implements ExpressHttpResponse {
  HttpResponse implHttpResponse;

  @override
  Future send([body]) {
    if (body is List<int>) {
      implHttpResponse.add(body);
    } else if (body is String) {
      implHttpResponse.write(body);
    } else {
      throw 'not supported';
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
  void add(List<int> bytes) => implHttpResponse.add(bytes);

  @override
  Future close() => implHttpResponse.close();

  @override
  void write(String content) => implHttpResponse.write(content);

  @override
  void writeln(String content) => implHttpResponse.write(content);

  @override
  Future redirect(Uri location, {int status}) => implHttpResponse
      .redirect(location, status: status ?? HttpStatus.movedTemporarily);

  /*
  @override
  Future redirect(Uri location, {int status}) {
    statusCode = status;
    headers.set("location", "$location");
    return close();
  }
   */
}

abstract class HttpRequestWrapperMixin implements ExpressHttpRequest {
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
