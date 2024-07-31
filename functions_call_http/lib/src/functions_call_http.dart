import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';

/// Firebase functions call service flutter
class FirebaseFunctionsCallServiceHttp implements FirebaseFunctionsCallService {
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
      //var appFlutter = app as FirebaseAppFlutter;

      return FirebaseFunctionsCallHttp(this);
    });
  }
}

/// Firebase functions call flutter
class FirebaseFunctionsCallHttp implements FirebaseFunctionsCall {
  /// Service
  final FirebaseFunctionsCallServiceHttp service;

  /// Constructor
  FirebaseFunctionsCallHttp(this.service);

  @override
  FirebaseFunctionsCallableHttp callable(String name,
      {FirebaseFunctionsCallableOptions? options}) {
    return FirebaseFunctionsCallableHttp(
      this,
    );
  }
}

/// Firebase functions callable flutter.
class FirebaseFunctionsCallableHttp implements FirebaseFunctionsCallable {
  /// Functions call flutter
  final FirebaseFunctionsCallHttp functionsCallHttp;

  /// Constructor
  FirebaseFunctionsCallableHttp(this.functionsCallHttp);

  @override
  Future<FirebaseFunctionsCallableResultFlutter> call<T>(
      [Object? parameters]) async {
    throw UnimplementedError('FirebaseFunctionsCallableHttp.call');
  }
}

/// Firebase functions callable result flutter.
class FirebaseFunctionsCallableResultFlutter<T>
    with FirebaseFunctionsCallableResultDefaultMixin<T>
    implements FirebaseFunctionsCallableResult<T> {
  /// Constructor
  FirebaseFunctionsCallableResultFlutter(this.data);

  @override
  final T data;
}
