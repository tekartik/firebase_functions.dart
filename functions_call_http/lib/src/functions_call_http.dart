import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_functions/utils.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http_mixin.dart';
import 'package:tekartik_http/http.dart';
import 'package:tekartik_http/http_client.dart';

/// Firebase functions call service Http
class FirebaseFunctionsCallServiceHttp
    with
        FirebaseProductServiceMixin<FirebaseFunctionsCall>,
        FirebaseFunctionsCallServiceDefaultMixin
    implements FirebaseFunctionsCallService {
  /// Http client factory
  final HttpClientFactory httpClientFactory;

  /// Constructor
  FirebaseFunctionsCallServiceHttp({required this.httpClientFactory});

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
  FirebaseFunctionsCallHttp functionsCall(FirebaseApp app,
      {required String region, Uri? baseUri}) {
    return _getInstance(app, region, () {
      return FirebaseFunctionsCallHttp(this, app, baseUri);
    });
  }
}

/// Firebase functions call Http
class FirebaseFunctionsCallHttp
    with FirebaseAppProductMixin<FirebaseFunctionsCall>
    implements FirebaseFunctionsCall {
  /// Service
  final FirebaseFunctionsCallServiceHttp service;

  /// App
  final FirebaseApp app;

  /// Base uri
  final Uri? baseUri;

  /// Constructor
  FirebaseFunctionsCallHttp(this.service, this.app, this.baseUri);

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
  Future<FirebaseFunctionsCallableResultHttp<T>> call<T>(
      [Object? parameters]) async {
    var service = functionsCallHttp.service;
    var httpClient = service.httpClientFactory.newClient();
    try {
      var baseUri = functionsCallHttp.baseUri;
      if (baseUri == null) {
        throw StateError('FirebaseFunctionsCallable.baseUri required');
      }
      var uri = Uri.parse(p.url.join(baseUri.toString(), name));

      /// Find current auth user if any
      var authUserId = (functionsCallHttp.app as FirebaseAppMixin)
          .getProduct<FirebaseAuth>()
          ?.currentUser
          ?.uid;

      var headers = <String, String>{
        if (authUserId != null) firebaseFunctionsHttpHeaderUid: authUserId
      };
      try {
        var text = await httpClientRead(httpClient, httpMethodPost, uri,
            headers: headers, body: jsonEncode(parameters));
        FirebaseFunctionsCallableResultHttp<T> result;
        if (text.isEmpty) {
          result = FirebaseFunctionsCallableResultHttp<T>(null as T);
        } else {
          var data = jsonDecode(text) as T;
          result = FirebaseFunctionsCallableResultHttp<T>(data);
        }
        return result;
      } catch (e, st) {
        var httpsError = anyExceptionToHttpsError(e, stackTrace: st);
        //devPrint('e: $e, httpsError: $httpsError');
        throw httpsError;
      }
    } finally {
      httpClient.close();
    }
  }

  @override
  String toString() => 'CallableHttp($name)';
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
