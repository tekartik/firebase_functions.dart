library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_http.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_http/src/import.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

Future<Object?> callHandler(CallRequest request) async {
  return {'uid': request.context.auth?.uid};
}

void main() {
  var dummyProjectId = 'dummyproject';
  var app = newFirebaseAppLocal(
      options: FirebaseAppOptions(projectId: dummyProjectId));

  var authService =
      FirebaseAuthServiceSembast(databaseFactory: newDatabaseFactoryMemory());
  var httpClientFactory = httpClientFactoryMemory;
  var firebaseFunctions = firebaseFunctionsServiceMemory.functions(app);
  var firebaseAuth = authService.auth(app);

  group('firebase_functions_memory', () {
    testHttp(
        firebaseAuth: firebaseAuth,
        firebaseFunctions: firebaseFunctions,
        httpClientFactory: httpClientFactory,
        app: app);
  });
}

void testHttp(
    {required FirebaseApp app,
    required FirebaseAuth firebaseAuth,
    required FirebaseFunctionsHttp firebaseFunctions,
    required HttpClientFactory httpClientFactory}) {
  group('custom', () {
    group('echo', () {
      HttpServer? server;

      late FirebaseFunctionsCall functionsCall;

      setUpAll(() async {
        firebaseFunctions['call'] = firebaseFunctions.https.onCall(callHandler);

        server = await firebaseFunctions.serveHttp(port: 0);

        var functionsCallService = FirebaseFunctionsCallServiceHttp(
          httpClientFactory: httpClientFactory,
        );

        functionsCall = functionsCallService.functionsCall(app,
            region: regionBelgium, baseUri: httpServerGetUri(server!));
      });

      test('call', () async {
        var result = await functionsCall.callable('call').call<Map>({});
        expect(result.data, {'uid': null});
      });

      test('call with auth', () async {
        var user = await firebaseAuth.signInWithEmailAndPassword(
            email: 'email', password: 'password');
        var uid = user.user.uid;
        var result = await functionsCall.callable('call').call<Map>({});

        expect(result.data, {'uid': uid});

        await firebaseAuth.signOut();
        result = await functionsCall.callable('call').call<Map>({});
        expect(result.data, {'uid': null});
      });

      tearDownAll(() async {
        await server!.close();
      });
    });
  });
}
