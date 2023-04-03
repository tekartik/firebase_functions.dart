import 'dart:convert';

import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:test/test.dart';

void main() {
  group('functions', () {
    test('requestBodyAsJsonObject', () {
      expect(requestBodyAsJsonObject('{}'), isEmpty);
      expect(requestBodyAsJsonObject('{"test":1}'), {'test': 1});
      expect(requestBodyAsJsonObject(''), null);
      expect(requestBodyAsJsonObject(null), null);
      expect(requestBodyAsJsonObject(<Object?>[]), null);
      expect(requestBodyAsJsonObject([1]), null);
      expect(requestBodyAsJsonObject(utf8.encode('{}')), isEmpty);
    });
  });
}
