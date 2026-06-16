import 'dart:async';

import 'package:cv/cv.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';

Future<Object?> basicCallHandler(
  FirebaseFunctions functions,
  CallRequest request,
) async {
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
      case 'project-id':
        return functions.app.projectId;
    }
    return {'no': 'command'};
  }
  return {'no': 'data'};
}

/// Init builders
void testFunctionsApiInitBuilders() {
  cvAddConstructors([TestApiRequest.new, TestApiResult.new]);
}

void initFunctionsBasic(
  FirebaseFunctions functions, {
  required String prefix,
  CallHandler? callHandler,
}) {
  functions.registerFunction(
    '${prefix}basic',
    functions.https.onCall(
      callHandler ?? (request) => basicCallHandler(functions, request),
      callableOptions: HttpsCallableOptions(region: regionBelgium),
    ),
  );
}

/// Test Api request
class TestApiRequest extends CvModelBase {
  /// Command name.
  final command = CvField<String>('command');

  @override
  List<CvField<Object?>> get fields => [command];
}

class TestApiResult extends CvModelBase {
  /// Result data.
  final data = CvField<Object>('data');

  @override
  List<CvField<Object?>> get fields => [data];
}
