import 'package:path/path.dart' as p;
import 'package:tekartik_app_http/app_http.dart';
// ignore: depend_on_referenced_packages
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth/auth_mixin.dart';
import 'package:tekartik_firebase_functions_call/functions_call_mixin.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http_mixin.dart';

import 'functions_call_http_helper.dart';

/// Global service instance.
final firebaseFunctionsCallServiceHttp = FirebaseFunctionsCallServiceHttp(
  httpClientFactory: httpClientFactoryUniversal,
);

/// Firebase functions call service Http
abstract class FirebaseFunctionsCallServiceHttp
    implements FirebaseFunctionsCallService {
  /// Factory constructor.
  factory FirebaseFunctionsCallServiceHttp({
    required HttpClientFactory httpClientFactory,
  }) => _FirebaseFunctionsCallServiceHttp(httpClientFactory: httpClientFactory);

  /// Http client factory.
  HttpClientFactory get httpClientFactory;
}

/// Firebase functions call service Http implementation.
class _FirebaseFunctionsCallServiceHttp
    with
        FirebaseProductServiceMixin<FirebaseFunctionsCall>,
        FirebaseFunctionsCallServiceDefaultMixin
    implements FirebaseFunctionsCallServiceHttp {
  /// Http client factory
  @override
  final HttpClientFactory httpClientFactory;

  /// Constructor
  _FirebaseFunctionsCallServiceHttp({required this.httpClientFactory});

  /// Most implementation need a single instance, keep it in memory!
  final _instances = <String, FirebaseFunctionsCallHttp>{};

  FirebaseFunctionsCallHttp _getInstance(
    App app,
    String region,
    FirebaseFunctionsCallHttp Function() createIfNotFound,
  ) {
    var key = '${app.name}_$region';
    var instance = _instances[key];
    if (instance == null) {
      var newInstance = instance = createIfNotFound();
      _instances[key] = newInstance;
    }
    return instance;
  }

  @override
  FirebaseFunctionsCall functionsCall(
    App app, {
    required FirebaseFunctionsCallOptions options,
  }) {
    return _getInstance(app, options.region, () {
      return FirebaseFunctionsCallHttp(this, app, options);
    });
  }
}

/// Firebase functions call Http
class FirebaseFunctionsCallHttp
    with
        FirebaseAppProductMixin<FirebaseFunctionsCall>,
        FirebaseFunctionsCallDefaultMixin
    implements FirebaseFunctionsCall {
  /// Service
  @override
  final FirebaseFunctionsCallServiceHttp service;

  /// App
  @override
  final FirebaseApp app;

  /// Options
  final FirebaseFunctionsCallOptions options;

  /// Base uri
  Uri? get baseUri => options.baseUri;

  /// Constructor
  FirebaseFunctionsCallHttp(this.service, this.app, this.options);

  @override
  FirebaseFunctionsCallableHttp callable(
    String name, {
    FirebaseFunctionsCallableOptions? options,
  }) {
    return _FirebaseFunctionsCallableHttp(this, name);
  }

  @override
  FirebaseFunctionsCallable callableFromUri(
    Uri uri, {
    FirebaseFunctionsCallableOptions? options,
  }) {
    return _FirebaseFunctionsCallableHttpFromUri(this, uri);
  }
}

/// Firebase functions callable Http.
abstract class FirebaseFunctionsCallableHttp
    implements FirebaseFunctionsCallable {}

/// Firebase functions callable Http.
class _FirebaseFunctionsCallableHttpFromUri
    extends _FirebaseFunctionsCallableHttp {
  final Uri uri;

  _FirebaseFunctionsCallableHttpFromUri(
    FirebaseFunctionsCallHttp functionsCallHttp,
    this.uri,
  ) : super(functionsCallHttp, uri.toString());

  @override
  Future<FirebaseFunctionsCallableResult<T>> call<T>([
    Object? parameters,
  ]) async {
    return await _callUri(uri, parameters: parameters);
  }
}

/// Firebase functions callable Http.
class _FirebaseFunctionsCallableHttp
    with FirebaseFunctionsCallableDefaultMixin
    implements FirebaseFunctionsCallableHttp {
  /// The function name
  @override
  final String name;

  /// Functions call Http
  final FirebaseFunctionsCallHttp functionsCallHttp;

  /// Constructor
  _FirebaseFunctionsCallableHttp(this.functionsCallHttp, this.name);

  Future<FirebaseFunctionsCallableResult<T>> _callUri<T>(
    Uri uri, {
    Object? parameters,
  }) async {
    var service = functionsCallHttp.service;
    var httpClient = service.httpClientFactory.newClient();
    try {
      var firebaseAuth = (functionsCallHttp.app as FirebaseAppMixin)
          .getProduct<FirebaseAuth>();
      var currentUser = (firebaseAuth as FirebaseAuthMixin).currentUser;

      /// Find current auth user if any
      var authUserId = currentUser?.uid;

      var headers = <String, String>{
        firebaseFunctionsHttpHeaderUid: ?authUserId,
      };
      return await firebaseFunctionsHttpCallUri(
        httpClient,
        uri,
        headers: headers,
        parameters: parameters,
      );
    } finally {
      httpClient.close();
    }
  }

  @override
  Future<FirebaseFunctionsCallableResult<T>> call<T>([
    Object? parameters,
  ]) async {
    var baseUri = functionsCallHttp.baseUri;
    if (baseUri == null) {
      throw StateError('FirebaseFunctionsCallable.baseUri required');
    }
    var uri = Uri.parse(p.url.join(baseUri.toString(), name));
    return await _callUri(uri, parameters: parameters);
  }

  @override
  String toString() => 'CallableHttp($name)';
}
