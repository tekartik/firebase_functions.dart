@TestOn('vm')
library;

import 'package:tekartik_app_web_socket/web_socket.dart';
import 'package:tekartik_firebase_functions/utils.dart'
    show anyExceptionToHttpsError;
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim.dart';
import 'package:tekartik_firebase_functions_call_sim/functions_call_sim_server.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_http_io/http_client_io.dart';
import 'package:test/test.dart';

/// The basic tests use callableFromUri, plus the sim call context and
/// options.
Future<void> main() async {
  var projectId = 'sim_basic_test';
  var prefix = 'sim';
  var firebaseSimServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryMemory,
    plugins: [
      FirebaseFunctionsCallSimPlugin(
        firebaseFunctionsService: firebaseFunctionsServiceMemory,
        options: FirebaseFunctionsCallSimPluginOptions(
          initFunctions: {
            projectId: ({required FirebaseApp firebaseApp}) async {
              var functions = firebaseFunctionsServiceMemory.functions(
                firebaseApp,
              );
              initFunctionsBasic(functions, prefix: prefix);
              functions['hasauth'] = functions.https.onCall(
                (request) async => {
                  'auth': request.context.auth != null,
                  'token': request.context.auth?.token,
                },
              );
              // An error whose details (a stack trace) are not JSON.
              functions['stackerror'] = functions.https.onCall((request) async {
                try {
                  throw StateError('stack error');
                } catch (e, st) {
                  throw anyExceptionToHttpsError(e, stackTrace: st);
                }
              });
              functions['slow'] = functions.https.onCall((request) async {
                await Future<void>.delayed(const Duration(seconds: 1));
                return 'slow';
              });
            },
          },
          httpPort: 0,
        ),
      ),
    ],
  );
  var clientApp = await (getFirebaseSim(
    clientFactory: webSocketChannelClientFactoryMemory,
    uri: firebaseSimServer.uri,
  )).initializeAppAsync(options: FirebaseAppOptions(projectId: projectId));
  var functionsCall = FirebaseFunctionsCallServiceSim().functionsCall(
    clientApp,
    options: FirebaseFunctionsCallOptions(region: regionBelgium),
  );
  var testClientContext = FirebaseFunctionsTestClientContext.urlTemplate(
    httpClientFactory: httpClientFactoryMemory,
    urlTemplate: '${firebaseSimServer.httpFunctionsUri}$prefix{{function}}',
    functionsCall: functionsCall,
  );

  test('callableFromUri without function name', () {
    expect(
      () => functionsCall.callableFromUri(Uri.parse('http://localhost/')),
      throwsArgumentError,
    );
  });
  basicTestGroup(() => testClientContext);

  test('call auth null when not authenticated', () async {
    var result = await functionsCall.callable('hasauth').call<Map>({});
    expect(result.data, {'auth': false, 'token': null});
  });
  test('call unknown function', () async {
    try {
      await functionsCall.callable('missing').call<Object?>({});
      fail('should fail');
    } on HttpsError catch (e) {
      expect(e.code, HttpsErrorCode.notFound);
    }
  });
  test('call error with details that are not JSON', () async {
    try {
      await functionsCall
          .callable('stackerror')
          .call<Object?>({})
          .timeout(const Duration(seconds: 10));
      fail('should fail');
    } on HttpsError catch (e) {
      expect(e.code, HttpsErrorCode.internal);
      expect(e.message, contains('stack error'));
      expect(e.details, isA<String>());
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
  test('call timeout', () async {
    try {
      await functionsCall
          .callable(
            'slow',
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

  tearDownAll(() async {
    await testClientContext.close();
    await firebaseSimServer.close();
  });
}
