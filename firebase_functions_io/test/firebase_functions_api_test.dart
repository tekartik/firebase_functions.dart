library;

import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:test/test.dart';

void main() {
  group('api', () {
    test('export', () {
      // ignore: unnecessary_statements
      FirebaseFunctionsHttp;

      if (!kDartIsWeb) {
        // ignore: unnecessary_statements
        firebaseFunctionsIo;
      }
    });
  });
}
