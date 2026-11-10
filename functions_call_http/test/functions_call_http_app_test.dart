library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_functions_call_http/functions_call_http.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_http/src/import.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  group('functions call app', () {
    late HttpServer server;
    late FirebaseFunctionsCallOptions options;
    late FirebaseFunctionsCallServiceHttp callService;

    setUpAll(() async {
      var functions = firebaseFunctionsServiceMemory.functions(
        newFirebaseAppLocal(name: 'server'),
      );
      functions['uid'] = functions.https.onCall(
        (request) async => {'uid': request.context.auth?.uid},
      );
      server = await functions.serveHttp(port: 0);
      options = FirebaseFunctionsCallOptions(
        region: regionBelgium,
        baseUri: httpServerGetUri(server),
      );
    });
    setUp(() {
      callService = FirebaseFunctionsCallServiceHttp(
        httpClientFactory: httpClientFactoryMemory,
      );
    });
    tearDownAll(() async {
      await server.close();
    });

    Future<Object?> callUid(FirebaseApp app) async =>
        (await callService
                .functionsCall(app, options: options)
                .callable('uid')
                .call<Map>({}))
            .data['uid'];

    /// A new app named [name], signed in as a new user [email].
    Future<(FirebaseApp, String)> signedInApp(String name, String email) async {
      var app = newFirebaseAppLocal(name: name);
      var auth = FirebaseAuthServiceSembast(
        databaseFactory: newDatabaseFactoryMemory(),
      ).auth(app);
      await auth.getOrCreateUserWithEmailAndPassword(
        email: email,
        password: 'password',
      );
      var credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: 'password',
      );
      return (app, credential.user.uid);
    }

    test('an app re-created with the same name calls as its user', () async {
      var (app1, uid1) = await signedInApp('client', 'user1');
      var functionsCall1 = callService.functionsCall(app1, options: options);
      expect(
        callService.functionsCall(app1, options: options),
        same(functionsCall1),
      );
      expect(await callUid(app1), uid1);
      await app1.delete();

      var (app2, uid2) = await signedInApp('client', 'user2');
      expect(uid2, isNot(uid1));
      var functionsCall2 = callService.functionsCall(app2, options: options);
      expect(functionsCall2, isNot(same(functionsCall1)));
      expect(functionsCall2.app, same(app2));
      expect(await callUid(app2), uid2);
      await app2.delete();
    });

    test('two live apps of the same name', () async {
      var (app1, uid1) = await signedInApp('same', 'user1');
      var (app2, uid2) = await signedInApp('same', 'user2');
      expect(await callUid(app1), uid1);
      expect(await callUid(app2), uid2);
      await app1.delete();
      await app2.delete();
    });
  });
}
