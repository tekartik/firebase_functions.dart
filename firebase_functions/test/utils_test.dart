import 'package:tekartik_firebase_functions/utils.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('HttpsError to http', () {
    var httpsError = HttpsError(HttpsErrorCode.notFound, 'not found', 'test');
    expect(httpsError.toHttpJson(), {
      'status': 'NOT_FOUND',
      'message': 'not found',
      'details': 'test',
    });
    expect(
      httpsErrorFromJsonMap(httpsError.toHttpJson()).toHttpJson(),
      httpsError.toHttpJson(),
    );
  });
}
