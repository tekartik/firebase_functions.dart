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

  /// The instances of each app (the app object, not its name: a new app of
  /// the same name has its own current user), by region and base uri,
  /// released when the app is deleted ([close]).
  final _appInstances = <App, Map<String, FirebaseFunctionsCallHttp>>{};

  FirebaseFunctionsCallHttp _getInstance(
    App app,
    FirebaseFunctionsCallOptions options,
    FirebaseFunctionsCallHttp Function() createIfNotFound,
  ) {
    var instances = _appInstances[app];
    if (instances == null) {
      _appInstances[app] = instances = <String, FirebaseFunctionsCallHttp>{};
      // close(app) is called when the app is deleted.
      app.addService(this);
    }
    // One instance per region and base uri.
    var key = '${options.region}_${options.baseUri}';
    return instances[key] ??= createIfNotFound();
  }

  @override
  Future<void> close(App app) async {
    _appInstances.remove(app);
    await super.close(app);
  }

  @override
  FirebaseFunctionsCall functionsCall(
    App app, {
    required FirebaseFunctionsCallOptions options,
  }) {
    return _getInstance(app, options, () {
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
    return _FirebaseFunctionsCallableHttp(this, name, options);
  }

  @override
  FirebaseFunctionsCallable callableFromUri(
    Uri uri, {
    FirebaseFunctionsCallableOptions? options,
  }) {
    return _FirebaseFunctionsCallableHttpFromUri(this, uri, options);
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
    FirebaseFunctionsCallableOptions? options,
  ) : super(functionsCallHttp, uri.toString(), options);

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

  /// Options, the timeout is applied when set.
  final FirebaseFunctionsCallableOptions? options;

  /// Constructor
  _FirebaseFunctionsCallableHttp(
    this.functionsCallHttp,
    this.name,
    this.options,
  );

  Future<FirebaseFunctionsCallableResult<T>> _callUri<T>(
    Uri uri, {
    Object? parameters,
  }) async {
    var service = functionsCallHttp.service;
    var httpClient = service.httpClientFactory.newClient();
    try {
      var firebaseAuth = (functionsCallHttp.app as FirebaseAppMixin)
          .getProduct<FirebaseAuth>();
      var currentUser = (firebaseAuth as FirebaseAuthMixin?)?.currentUser;

      /// Find current auth user if any
      var authUserId = currentUser?.uid;

      var headers = <String, String>{
        firebaseFunctionsHttpHeaderUid: ?authUserId,
      };
      var resultFuture = firebaseFunctionsHttpCallUri<T>(
        httpClient,
        uri,
        headers: headers,
        parameters: parameters,
      );
      var timeout = options?.timeout;
      if (timeout == null) {
        return await resultFuture;
      }
      return await resultFuture.timeout(
        timeout,
        onTimeout: () => throw HttpsError(
          HttpsErrorCode.deadlineExceeded,
          'deadline-exceeded',
          null,
        ),
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
