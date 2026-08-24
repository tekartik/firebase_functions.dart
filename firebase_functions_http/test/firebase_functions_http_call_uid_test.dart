library;

import 'package:tekartik_firebase_functions_http/firebase_functions_http_mixin.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_http/src/import.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

/// The `x-tekartik-firebase-call-uid` header is a simulation shortcut: it is
/// not authenticated, so it must only be honoured on a debug/test server.
void main() {
  // Read eagerly: the tests below mutate the flag, and a lazy top level
  // would capture the mutated value instead of the default.
  var defaultAllowCallUidHeader = debugFirebaseFunctionsHttpAllowCallUidHeader;
  late HttpServer server;
  late Uri callUri;
  late Client client;

  setUpAll(() async {
    var app = newFirebaseAppMemory();
    var firebaseFunctions = firebaseFunctionsServiceMemory.functions(app);
    firebaseFunctions.registerFunction(
      'uid',
      firebaseFunctions.https.onCall(
        (request) async => {'uid': request.context.auth?.uid},
        callableOptions: HttpsCallableOptions(region: regionBelgium),
      ),
    );
    server = await firebaseFunctions.serveHttp(port: 0);
    callUri = httpServerGetUri(server).replace(path: 'uid');
    client = httpClientFactoryMemory.newClient();
  });

  tearDownAll(() async {
    client.close();
    await server.close();
    debugFirebaseFunctionsHttpAllowCallUidHeader = defaultAllowCallUidHeader;
  });

  /// Call the function claiming to be [uid] through the (unauthenticated)
  /// header, and return the uid the function actually saw.
  Future<Object?> callAs(String uid) async {
    var text = await httpClientRead(
      client,
      httpMethodPost,
      callUri,
      headers: {
        httpHeaderContentType: httpContentTypeJson,
        firebaseFunctionsHttpHeaderUid: uid,
      },
      body: jsonEncode({'data': <String, Object?>{}}),
    );
    return ((jsonDecode(text) as Map)['result'] as Map)['uid'];
  }

  test('honoured when allowed', () async {
    debugFirebaseFunctionsHttpAllowCallUidHeader = true;
    expect(await callAs('user1'), 'user1');
  });

  test('ignored when not allowed', () async {
    debugFirebaseFunctionsHttpAllowCallUidHeader = false;
    expect(await callAs('user1'), isNull);
  });

  test('allowed by default in debug (asserts enabled)', () {
    var assertsEnabled = false;
    assert(() {
      assertsEnabled = true;
      return true;
    }());
    // Tests run with asserts on, so the default must be true here; in a
    // release/AOT build the same expression yields false.
    expect(defaultAllowCallUidHeader, assertsEnabled);
    expect(assertsEnabled, isTrue);
  });
}
