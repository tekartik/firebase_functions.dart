import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:tekartik_firebase_functions_sim/functions_sim.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

import 'test_common.dart';

Future<void> main() async {
  group('sign_in', () {
    late FirebaseApp app;
    late FirebaseFunctionsSim functions;
    late FirebaseFunctionsServiceSim functionsService;
    late TestContext testContext;
    setUp(() async {
      testContext = await initTestContextSim();
      functionsService = FirebaseFunctionsServiceSim();
      app = testContext.firebase.initializeApp();
      functions = functionsService.functions(app);
    });

    tearDownAll(() {
      return app.delete();
    });

    test('dummy', () {
      functions.hashCode;
    });
  });
}
