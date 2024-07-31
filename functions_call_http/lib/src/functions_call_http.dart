import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_http/http.dart';
import 'package:tekartik_http/http_client.dart';

/// Firebase functions call service Http
class FirebaseFunctionsCallServiceHttp
    with FirebaseFunctionsCallServiceDefaultMixin
    implements FirebaseFunctionsCallService {
  /// Http client factory
  final HttpClientFactory httpClientFactory;

  /// Base uri
  final Uri baseUri;

  /// Constructor
  FirebaseFunctionsCallServiceHttp(
      {required this.httpClientFactory, required this.baseUri});

  /// Most implementation need a single instance, keep it in memory!
  final _instances = <String, FirebaseFunctionsCallHttp>{};

  FirebaseFunctionsCallHttp _getInstance(App app, String region,
      FirebaseFunctionsCallHttp Function() createIfNotFound) {
    var key = '${app.name}_$region';
    var instance = _instances[key];
    if (instance == null) {
      var newInstance = instance = createIfNotFound();
      _instances[key] = newInstance;
    }
    return instance;
  }

  @override
  FirebaseFunctionsCallHttp functionsCall(App app, {required String region}) {
    return _getInstance(app, region, () {
      //assert(app is FirebaseAppLocal, 'invalid firebase app type');
      //var appHttp = app as FirebaseAppHttp;

      return FirebaseFunctionsCallHttp(this);
    });
  }
}

/// Firebase functions call Http
class FirebaseFunctionsCallHttp implements FirebaseFunctionsCall {
  /// Service
  final FirebaseFunctionsCallServiceHttp service;

  /// Constructor
  FirebaseFunctionsCallHttp(this.service);

  @override
  FirebaseFunctionsCallableHttp callable(String name,
      {FirebaseFunctionsCallableOptions? options}) {
    return FirebaseFunctionsCallableHttp(this, name);
  }
}

/// Firebase functions callable Http.
class FirebaseFunctionsCallableHttp implements FirebaseFunctionsCallable {
  /// The function name
  final String name;

  /// Functions call Http
  final FirebaseFunctionsCallHttp functionsCallHttp;

  /// Constructor
  FirebaseFunctionsCallableHttp(this.functionsCallHttp, this.name);

  @override
  Future<FirebaseFunctionsCallableResultHttp> call<T>(
      [Object? parameters]) async {
    var service = functionsCallHttp.service;
    var httpClient = service.httpClientFactory.newClient();
    try {
      var baseUri = service.baseUri;
      var uri = Uri.parse(p.url.join(baseUri.toString(), name));
      // TODO add auth headers if any
      var text = await httpClientRead(httpClient, httpMethodPost, uri);
      var data = jsonDecode(text) as T;
      var result = FirebaseFunctionsCallableResultHttp<T>(data);
      return result;
    } finally {
      httpClient.close();
    }
  }
}

/// Firebase functions callable result Http.
class FirebaseFunctionsCallableResultHttp<T>
    with FirebaseFunctionsCallableResultDefaultMixin<T>
    implements FirebaseFunctionsCallableResult<T> {
  /// Constructor
  FirebaseFunctionsCallableResultHttp(this.data);

  @override
  final T data;
}
