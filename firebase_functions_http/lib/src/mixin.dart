import '../firebase_functions_http.dart';

final firebaseFunctionsHttpHeaderUid = 'x-tekartik-firebase-call-uid';

/// Mixin helper
extension FirebaseFunctionsHttpMixinExt on FirebaseFunctionsHttp {
  /// Functions access
  Map<String, Object?> get functions =>
      (this as FirebaseFunctionsHttpBase).functions;
}
