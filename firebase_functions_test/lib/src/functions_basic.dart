import 'package:tekartik_firebase_functions/firebase_functions.dart';

Future<Object?> basicCallHandler(CallRequest request) async {
  var data = request.data;
  if (data is Map) {
    var command = data['command'];
    switch (command) {
      case 'echo':
        return data['data'];
      case 'not-found':
        throw HttpsError(
          HttpsErrorCode.notFound,
          'Not found',
          'command $command',
        );
    }
    return {'no': 'command'};
  }
  return {'no': 'data'};
}

void initFunctionsBasic(FirebaseFunctions functions, {required String prefix}) {
  functions.registerFunction(
    '${prefix}basic',
    functions.https.onCall(
      basicCallHandler,
      callableOptions: HttpsCallableOptions(region: regionBelgium),
    ),
  );
}
