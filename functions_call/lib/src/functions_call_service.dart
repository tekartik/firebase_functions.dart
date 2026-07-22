import 'package:tekartik_firebase_functions_call/functions_call.dart';

/// Options controlling how [FirebaseFunctionsCallService.functionsCall]
/// creates a [FirebaseFunctionsCall] instance, such as the target [region].
class FirebaseFunctionsCallOptions {
  /// The Cloud Functions region in which the 1st gen Callable functions
  /// used through the resulting [FirebaseFunctionsCall] are deployed (for
  /// example one of `regionBelgium`, `regionUsCentral1`,
  /// `regionFrankfurt` exported from `functions_call.dart`).
  ///
  /// Not relevant for 2nd gen functions invoked through
  /// [FirebaseFunctionsCall.callableFromUri], which target a specific
  /// [Uri] directly.
  final String region;

  /// The base [Uri] used to reach Callable functions, overriding the
  /// default Cloud Functions endpoint derived from [region].
  ///
  /// `null` (the default) means the standard Cloud Functions endpoint for
  /// [region] is used. Not used on Flutter, where the native SDK resolves
  /// the endpoint itself.
  Uri? baseUri;

  /// Constructs a new [FirebaseFunctionsCallOptions] targeting the given
  /// [region], optionally overriding the endpoint with [baseUri].
  FirebaseFunctionsCallOptions({required this.region, this.baseUri});

  @override
  String toString() =>
      'FirebaseFunctionsCallOptions(region: $region${baseUri != null ? ', baseUri: $baseUri' : ''})';
}

/// Creates [FirebaseFunctionsCall] instances for a given [App].
///
/// Implementations are typically looked up through platform-specific
/// plugin registration and are not normally constructed directly by
/// application code; use [FirebaseFunctionsCall.instance] or the
/// app-specific product lookup instead once a [FirebaseFunctionsCall] has
/// been registered through this service.
abstract class FirebaseFunctionsCallService {
  /// Creates a [FirebaseFunctionsCall] instance for [app] targeting
  /// [region], optionally overriding the endpoint with [baseUri] (not used
  /// on Flutter).
  ///
  /// Deprecated: use [functionsCall] with a [FirebaseFunctionsCallOptions]
  /// instead.
  @Deprecated('Use functionsCall instead')
  FirebaseFunctionsCall functionsCallObsolete(
    App app, {
    required String region,

    /// Not used in flutter
    Uri? baseUri,
  });

  /// Creates a [FirebaseFunctionsCall] instance for [app] configured with
  /// [options].
  FirebaseFunctionsCall functionsCall(
    App app, {
    required FirebaseFunctionsCallOptions options,
  });
}

/// Default mixin for [FirebaseFunctionsCallService] implementations.
///
/// [functionsCallObsolete] delegates to [functionsCall] by default;
/// [functionsCall] itself throws [UnimplementedError] until overridden by
/// the mixing class. See `functions_call_mixin.dart` for the rationale
/// behind this pattern.
mixin FirebaseFunctionsCallServiceDefaultMixin
    implements FirebaseFunctionsCallService {
  /// Delegates to [functionsCall] with [region] wrapped in a
  /// [FirebaseFunctionsCallOptions].
  @override
  FirebaseFunctionsCall functionsCallObsolete(
    App app, {
    required String region,
    Uri? baseUri,
  }) {
    return functionsCall(
      app,
      options: FirebaseFunctionsCallOptions(region: region),
    );
  }

  /// Throws [UnimplementedError] unless overridden by the mixing class.
  @override
  FirebaseFunctionsCall functionsCall(
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
