import '../firebase_functions_http.dart';

/// Header key for passing user ID in call requests.
final firebaseFunctionsHttpHeaderUid = 'x-tekartik-firebase-call-uid';

bool _assertsEnabled() {
  var enabled = false;
  assert(() {
    enabled = true;
    return true;
  }());
  return enabled;
}

/// Whether the [firebaseFunctionsHttpHeaderUid] header is honoured as the
/// caller identity.
///
/// This is a simulation shortcut: the header is NOT authenticated, any client
/// can claim any uid, so it must never be trusted outside of a local
/// development or test server.
///
/// It defaults to true when asserts are enabled (`dart test`, `dart run`,
/// flutter debug) and false in a release/AOT build, so a compiled server never
/// trusts it. Set it explicitly to opt a compiled local test server back in.
var debugFirebaseFunctionsHttpAllowCallUidHeader = _assertsEnabled();

/// Mixin helper
extension FirebaseFunctionsHttpMixinExt on FirebaseFunctionsHttp {
  /// Functions access
  Map<String, Object?> get functions =>
      (this as FirebaseFunctionsHttpBase).functions;
}
