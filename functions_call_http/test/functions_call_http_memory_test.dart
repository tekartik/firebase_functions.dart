library;

import 'package:sembast/sembast_memory.dart';
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
    options: FirebaseAppOptions(projectId: dummyProjectId),
  );

  var authService = FirebaseAuthServiceSembast(
    databaseFactory: newDatabaseFactoryMemory(),
  );
  var httpClientFactory = httpClientFactoryMemory;
  var firebaseFunctions = firebaseFunctionsServiceMemory.functions(app);
  var firebaseAuth = authService.auth(app);

  group('firebase_functions_memory', () {
    testHttp(
      firebaseAuth: firebaseAuth,
      firebaseFunctions: firebaseFunctions,
      httpClientFactory: httpClientFactory,
      app: app,
    );
  });
}

void testHttp({
  required FirebaseApp app,
  required FirebaseAuth firebaseAuth,
  required FirebaseFunctionsHttp firebaseFunctions,
  required HttpClientFactory httpClientFactory,
}) {
  group('custom', () {
    group('echo', () {
      HttpServer? server;

      late FirebaseFunctionsCall functionsCall;

      setUpAll(() async {
        firebaseFunctions['call'] = firebaseFunctions.https.onCall(callHandler);
        firebaseFunctions['callhasauth'] = firebaseFunctions.https.onCall(
          (request) async => {'auth': request.context.auth != null},
        );
        firebaseFunctions['callerror'] = firebaseFunctions.https.onCall((
          request,
        ) async {
          var code = (request.data as Map)['code'] as String;
          throw HttpsError(code, 'error $code', 'details $code');
        });
        firebaseFunctions['callslow'] = firebaseFunctions.https.onCall((
          request,
        ) async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return 'slow';
        });

        server = await firebaseFunctions.serveHttp(port: 0);

        var functionsCallService = FirebaseFunctionsCallServiceHttp(
          httpClientFactory: httpClientFactory,
        );

        await firebaseAuth.getOrCreateUserWithEmailAndPassword(
          email: 'email',
          password: 'password',
        );
        functionsCall = functionsCallService.functionsCall(
          app,
          options: FirebaseFunctionsCallOptions(
            region: regionBelgium,
            baseUri: httpServerGetUri(server!),
          ),
        );
      });

      test('call', () async {
        var result = await functionsCall.callable('call').call<Map>({});
        expect(result.data, {'uid': null});
      });

      test('call with auth', () async {
        var user = await firebaseAuth.signInWithEmailAndPassword(
          email: 'email',
          password: 'password',
        );
        var uid = user.user.uid;
        var result = await functionsCall.callable('call').call<Map>({});

        expect(result.data, {'uid': uid});

        await firebaseAuth.signOut();
        result = await functionsCall.callable('call').call<Map>({});
        expect(result.data, {'uid': null});
      });

      test('call auth null when not authenticated', () async {
        var result = await functionsCall.callable('callhasauth').call<Map>({});
        expect(result.data, {'auth': false});
        await firebaseAuth.signInWithEmailAndPassword(
          email: 'email',
          password: 'password',
        );
        result = await functionsCall.callable('callhasauth').call<Map>({});
        expect(result.data, {'auth': true});
        await firebaseAuth.signOut();
      });

      test('call error codes', () async {
        for (var code in [
          HttpsErrorCode.cancelled,
          HttpsErrorCode.unknown,
          HttpsErrorCode.invalidArgument,
          HttpsErrorCode.deadlineExceeded,
          HttpsErrorCode.notFound,
          HttpsErrorCode.alreadyExists,
          HttpsErrorCode.permissionDenied,
          HttpsErrorCode.resourceExhausted,
          HttpsErrorCode.failedPrecondition,
          HttpsErrorCode.aborted,
          HttpsErrorCode.outOrRange,
          HttpsErrorCode.unimplemented,
          HttpsErrorCode.internal,
          HttpsErrorCode.unavailable,
          HttpsErrorCode.dataLoss,
          HttpsErrorCode.unauthenticated,
        ]) {
          try {
            await functionsCall.callable('callerror').call<Object?>({
              'code': code,
            });
            fail('should fail');
          } on HttpsError catch (e) {
            expect(e.code, code);
            expect(e.message, 'error $code');
            expect(e.details, 'details $code');
          }
        }
      });

      test('call timeout', () async {
        try {
          await functionsCall
              .callable(
                'callslow',
                options: FirebaseFunctionsCallableOptions(
                  timeout: const Duration(milliseconds: 100),
                ),
              )
              .call<Object?>({});
          fail('should fail');
        } on HttpsError catch (e) {
          expect(e.code, HttpsErrorCode.deadlineExceeded);
        }
      });

      test('one instance per base uri', () async {
        var functionsCallService = FirebaseFunctionsCallServiceHttp(
          httpClientFactory: httpClientFactory,
        );
        FirebaseFunctionsCall get(String baseUri) =>
            functionsCallService.functionsCall(
              app,
              options: FirebaseFunctionsCallOptions(
                region: regionBelgium,
                baseUri: Uri.parse(baseUri),
              ),
            );
        expect(get('http://a/'), same(get('http://a/')));
        expect(get('http://a/'), isNot(same(get('http://b/'))));
      });

      test('functionsCallObsolete base uri', () async {
        var functionsCallService = FirebaseFunctionsCallServiceHttp(
          httpClientFactory: httpClientFactory,
        );
        // ignore: deprecated_member_use
        var functionsCall = functionsCallService.functionsCallObsolete(
          app,
          region: regionBelgium,
          baseUri: httpServerGetUri(server!),
        );
        var result = await functionsCall.callable('call').call<Map>({});
        expect(result.data, {'uid': null});
      });

      tearDownAll(() async {
        await server!.close();
      });
    });
  });
}
