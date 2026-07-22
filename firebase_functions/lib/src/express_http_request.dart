import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tekartik_http/http.dart';
import 'package:tekartik_http/src/utils.dart'; // ignore: implementation_imports

/// Converts a raw request/response [body] to its text representation.
///
/// [body] must be one of `String` (returned as-is), `Uint8List` (decoded
/// as UTF-8), or `Map`/`List` (JSON-encoded).
///
/// Throws an [UnsupportedError] if [body] is of any other type.
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
  throw UnsupportedError('body $body not text');
}

/// Converts a raw request/response [body] to a `Map<String, Object?>`, if
/// possible.
///
/// [body] can be `null` (returns `null`), a `Map` (cast as-is), a `String`
/// (parsed as JSON; returns `null` if it does not decode to a JSON
/// object), or a `List` (converted to text first, then parsed as JSON).
///
/// Returns `null` when [body] is `null` or is a `String` that does not
/// decode to a JSON object.
///
/// Throws an [UnsupportedError] if [body] is of any other type.
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
  throw UnsupportedError('body $body not json object');
}

/// An incoming HTTPS request as delivered to a [RequestHandler], wrapping
/// the underlying platform request (e.g. an Express-style request on
/// Node.js).
abstract class ExpressHttpRequest {
  // String, List<int>, Map
  /// The raw request body, typically a `String`, `List<int>` or `Map`
  /// depending on how the platform decoded it, or `null` if there is no
  /// body.
  Object? get body;

  /// The request [Uri], including path and query parameters.
  Uri get uri;

  /// The [ExpressHttpResponse] used to write the response for this
  /// request.
  ExpressHttpResponse get response;

  /// The HTTP method of the request (e.g. `'GET'`, `'POST'`).
  String get method;

  /// The HTTP request headers.
  HttpHeaders get headers;

  /// The requested [Uri]. Deprecated, use [uri] instead.
  @Deprecated('Use uri')
  Uri get requestedUri;
}

/// Convenience accessors to interpret an [ExpressHttpRequest.body] as JSON
/// or text.
extension ExpressHttpRequestExt on ExpressHttpRequest {
  /// The request [ExpressHttpRequest.body] as a `Map<String, Object?>`.
  ///
  /// Throws if the body is `null` or cannot be interpreted as a JSON
  /// object.
  Map<String, Object?> get bodyAsMap => bodyAsMapOrNull!;

  /// The request [ExpressHttpRequest.body] as a `Map<String, Object?>`, or
  /// `null` if the body is missing or cannot be interpreted as a JSON
  /// object.
  Map<String, Object?>? get bodyAsMapOrNull => httpDataAsMapOrNull(body);

  /// The request [ExpressHttpRequest.body] converted to text, or `null` if
  /// unavailable. Deprecated, use [bodyAsString] instead.
  @Deprecated('Use bodyAsString')
  String? get bodyAsText => requestBodyAsText(body);

  /// The request [ExpressHttpRequest.body] converted to its text
  /// representation.
  ///
  /// Throws if the body is `null`.
  String get bodyAsString => httpDataAsString(body!);
}

/// The response side of an HTTPS request, used by [RequestHandler]s to
/// write and finish the response to an [ExpressHttpRequest].
abstract class ExpressHttpResponse {
  /// Writes [body] (if any) and closes the response, in a single step.
  ///
  /// [body] can be a `String`, `Uint8List`/`List<int>`, `Map` or `List`
  /// (the latter two are JSON-encoded); if omitted, only [close] is
  /// effectively performed. Node only supports this method to terminate a
  /// response.
  ///
  /// The returned [Future] completes once the response has been sent.
  Future send([Object? body]);

  /// Redirects the response to [location].
  ///
  /// [status] is the HTTP redirect status code to use; if omitted, an
  /// implementation-defined default (typically 302) is used.
  ///
  /// The returned [Future] completes once the redirect response has been
  /// sent.
  Future redirect(Uri location, {int? status});

  /// Writes [content] to the response body without closing the response.
  void write(String content);

  /// Writes [content] followed by a newline to the response body without
  /// closing the response.
  void writeln(String content);

  /// Appends raw [bytes] to the response body without closing the
  /// response.
  void add(Uint8List bytes);

  /// The HTTP status code of the response.
  int get statusCode;

  /// Sets the HTTP status code of the response.
  set statusCode(int statusCode);

  /// Closes the response. Call this if the response was written using
  /// [write]/[writeln]/[add] rather than [send].
  ///
  /// The returned [Future] completes once the response has been closed.
  Future close();

  /// The HTTP response headers.
  HttpHeaders get headers;
}

/// Base class for [ExpressHttpRequest] implementations that wrap a
/// platform `dart:io`-style [HttpRequest], typically used when running as
/// a plain Dart HTTP server rather than on Node.js.
abstract class ExpressHttpRequestWrapperBase extends Object
    with HttpRequestWrapperMixin {
  /// The wrapped platform [HttpRequest].
  @override
  final HttpRequest implHttpRequest;
  @override
  final Uri _rewrittenUri;

  /// Creates a wrapper around [implHttpRequest]. The second positional
  /// argument is the rewritten [Uri] (typically the request uri after
  /// removing a mount-path prefix) exposed as [ExpressHttpRequest.uri].
  ExpressHttpRequestWrapperBase(this.implHttpRequest, this._rewrittenUri);
}

/// Base class for [ExpressHttpResponse] implementations that wrap a
/// platform `dart:io`-style [HttpResponse], typically used when running as
/// a plain Dart HTTP server rather than on Node.js.
abstract class ExpressHttpResponseWrapperBase extends Object
    with HttpResponseWrapperMixin {
  /// Creates a wrapper around [implHttpResponse].
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
        throw UnsupportedError('${body.runtimeType} not supported');
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
