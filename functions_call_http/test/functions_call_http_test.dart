library;

import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_firebase_functions_call_http/src/functions_call_http.dart';
import 'package:test/test.dart';

void main() {
  group('functions_call_http', () {
    test('api', () {
      // ignore: unnecessary_statements
      [
        FirebaseFunctionsCallServiceHttp,
        // Make sure the exported symbols are available
        FirebaseFunctionsCallService,
      ];
    });
  });
}
