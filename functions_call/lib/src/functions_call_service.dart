import 'package:tekartik_firebase_functions_call/functions_call.dart';

/// Interface representing an HttpsCallable instance's options,
class FirebaseFunctionsCallOptions {
  /// Region
  final String region;

  /// Not used in flutter
  Uri? baseUri;

  /// Constructs a new [FirebaseFunctionsCallOptions]
  FirebaseFunctionsCallOptions({required this.region, this.baseUri});

  @override
  String toString() =>
      'FirebaseFunctionsCallOptions(region: $region${baseUri != null ? ', baseUri: $baseUri' : ''})';
}

/// Firebase functions call service
abstract class FirebaseFunctionsCallService {
  /// Get the firebase functions call instance
  @Deprecated('Use functionsCall2 instead')
  FirebaseFunctionsCall functionsCall(
    App app, {
    required String region,

    /// Not used in flutter
    Uri? baseUri,
  });

  /// Get the firebase functions call instance
  FirebaseFunctionsCall functionsCall2(
    App app, {
    required FirebaseFunctionsCallOptions options,
  });
}

/// Firebase functions call service default mixin
mixin FirebaseFunctionsCallServiceDefaultMixin
    implements FirebaseFunctionsCallService {
  @override
  FirebaseFunctionsCall functionsCall(
    App app, {
    required String region,
    Uri? baseUri,
  }) {
    return functionsCall2(
      app,
      options: FirebaseFunctionsCallOptions(region: region),
    );
  }

  @override
  FirebaseFunctionsCall functionsCall2(
    App app, {
    required FirebaseFunctionsCallOptions options,
  }) {
    throw UnimplementedError(
      'FirebaseFunctionsCallService.functionsCall2(${app.name}, $options)',
    );
  }
}

// ignore: unused_element
class _FirebaseFunctionsCallServiceMock
    with FirebaseFunctionsCallServiceDefaultMixin
    implements FirebaseFunctionsCallService {}
