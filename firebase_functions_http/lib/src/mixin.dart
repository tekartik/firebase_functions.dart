import '../firebase_functions_http.dart';

/// Header key for passing user ID in call requests.
final firebaseFunctionsHttpHeaderUid = 'x-tekartik-firebase-call-uid';

/// Mixin helper
extension FirebaseFunctionsHttpMixinExt on FirebaseFunctionsHttp {
  /// Functions access
  Map<String, Object?> get functions =>
      (this as FirebaseFunctionsHttpBase).functions;
}
