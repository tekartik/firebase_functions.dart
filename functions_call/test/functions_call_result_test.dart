import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:test/test.dart';

void main() {
  group('FirebaseFunctionsCallableResult', () {
    test('dataAsMapOrNull', () {
      Map<String, Object?>? mapOrNull(Object? data) =>
          FirebaseFunctionsCallableResult<Object?>(data).dataAsMapOrNull;
      expect(mapOrNull({'a': 1}), {'a': 1});
      expect(mapOrNull('{"a":1}'), {'a': 1});
      // Any other json value of a callable is not a map: null, no error.
      for (var data in <Object?>[
        null,
        42,
        1.5,
        true,
        'text',
        '[1]',
        [1],
      ]) {
        expect(mapOrNull(data), isNull, reason: '$data');
      }
    });

    test('dataAsMap and dataAsText', () {
      var result = FirebaseFunctionsCallableResult<Object?>({'a': 1});
      expect(result.dataAsMap, {'a': 1});
      expect(result.dataAsText, '{"a":1}');
      expect(
        FirebaseFunctionsCallableResult<Object?>('text').dataAsText,
        'text',
      );
      expect(
        () => FirebaseFunctionsCallableResult<Object?>(42).dataAsMap,
        throwsA(isA<TypeError>()),
      );
    });
  });
}
