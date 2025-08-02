import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_firebase_functions_test/constants.dart';
// ignore: depend_on_referenced_packages
import 'package:test/test.dart';

import 'constants.dart';
import 'firebase_functions_test.dart';

export 'package:tekartik_firebase_functions/firebase_functions.dart';
export 'package:tekartik_http/http_utils.dart';

/// Test
abstract class FirebaseFunctionsCallTestClientContext {
  FirebaseFunctionsCall get functionsCall;

  factory FirebaseFunctionsCallTestClientContext({
    required FirebaseFunctionsCall functionsCall,
  }) => _FirebaseFunctionsCallTestClientContext(functionsCall: functionsCall);
}

class _FirebaseFunctionsCallTestClientContext
    implements FirebaseFunctionsCallTestClientContext {
  @override
  final FirebaseFunctionsCall functionsCall;

  _FirebaseFunctionsCallTestClientContext({required this.functionsCall});
}

void ffCallTestGroup({
  required FirebaseFunctionsCallTestClientContext testContext,
}) {
  group('testFunction', () {
    group('call $callableFunctionTestName', () {
      late CallFunctionTestClient client;

      setUpAll(() async {
        client = CallFunctionTestClient(
          testContext.functionsCall.callable(callableFunctionTestName),
        );
      });

      test('data', () async {
        await client.testData();
      });
      test('throw', () async {
        try {
          await client.sendThrow();
        } on HttpsError catch (e) {
          print('error: $e');
          expect(e.code, 'internal');
        } catch (e) {
          print('error: $e (${e.runtimeType})');
          rethrow;
        }
      }, skip: true);

      test('not-found', () async {
        try {
          await client.sendNotFound();
        } on HttpsError catch (e) {
          expect(e.code, HttpsErrorCode.notFound);
        } catch (e) {
          print('error: $e (${e.runtimeType})');
          rethrow;
        }
      });
      test('raw all', () async {
        for (var raw in [
          <String, Object?>{'test': 1},
          <String, Object?>{},
          <Object?>[],
          'test',
          true,
        ]) {
          var result = await client.sendRaw(raw);
          expect(result, raw);
        }
      }, skip: true);

      Future<void> checkRaw(Object? raw) async {
        var result = await client.sendRaw(raw);
        expect(result, raw);
      }

      test('raw null', () async {
        await checkRaw(null);
      });

      tearDownAll(() async {
        await client.close();
      });
    });
  });
}

class CallFunctionTestClient extends FunctionTestClient {
  final FirebaseFunctionsCallable functionsCallable;

  CallFunctionTestClient(this.functionsCallable);

  @override
  Future<Object?> rawSend(FunctionTestInputData data) async {
    var result = await functionsCallable.call<Object?>(data.toMap());
    return result.data;
  }

  @override
  Future<FunctionTestOutputData> send(FunctionTestInputData data) async {
    var result = await functionsCallable.call<Map>(data.toMap());
    return FunctionTestOutputData.fromMap(result.data);
  }
}
