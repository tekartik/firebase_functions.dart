@TestOn('vm')
library;

import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart'
    as io;
import 'package:tekartik_firebase_functions_sim/firebase_functions_sim.dart';
import 'package:test/test.dart';

void main() {
  group('api', () {
    test('export', () {
      // ignore: unnecessary_statements
      FirebaseFunctionsHttp;
    });
    test('firebaseFunctionsServiceSim', () {
      // Tested in firebase_functions_io (firebase_functions_http_io_test).
      expect(firebaseFunctionsServiceSim, same(io.firebaseFunctionsServiceIo));
    });
  });
}
