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
  test('error codes', () {
    var codes = {
      HttpsErrorCode.cancelled: (499, 'CANCELLED'),
      HttpsErrorCode.unknown: (500, 'UNKNOWN'),
      HttpsErrorCode.invalidArgument: (400, 'INVALID_ARGUMENT'),
      HttpsErrorCode.deadlineExceeded: (504, 'DEADLINE_EXCEEDED'),
      HttpsErrorCode.notFound: (404, 'NOT_FOUND'),
      HttpsErrorCode.alreadyExists: (409, 'ALREADY_EXISTS'),
      HttpsErrorCode.permissionDenied: (403, 'PERMISSION_DENIED'),
      HttpsErrorCode.resourceExhausted: (429, 'RESOURCE_EXHAUSTED'),
      HttpsErrorCode.failedPrecondition: (400, 'FAILED_PRECONDITION'),
      HttpsErrorCode.aborted: (409, 'ABORTED'),
      HttpsErrorCode.outOrRange: (400, 'OUT_OF_RANGE'),
      HttpsErrorCode.unimplemented: (501, 'UNIMPLEMENTED'),
      HttpsErrorCode.internal: (500, 'INTERNAL'),
      HttpsErrorCode.unavailable: (503, 'UNAVAILABLE'),
      HttpsErrorCode.dataLoss: (500, 'DATA_LOSS'),
      HttpsErrorCode.unauthenticated: (401, 'UNAUTHENTICATED'),
    };
    codes.forEach((code, statusAndName) {
      var (status, name) = statusAndName;
      expect(httpsErrorCodeToStatusCode(code), status, reason: code);
      expect(statusErrorCodeToHttpStatusCode(code), name, reason: code);
      var httpsError = HttpsError(code, 'message', null);
      expect(httpsError.toHttpJson()['status'], name);
      expect(httpsErrorFromJsonMap(httpsError.toHttpJson()).code, code);
    });
    expect(statusCodeToHttpsErrorCode(401), HttpsErrorCode.unauthenticated);
    expect(statusCodeToHttpsErrorCode(403), HttpsErrorCode.permissionDenied);
    expect(statusCodeToHttpsErrorCode(400), HttpsErrorCode.invalidArgument);
    expect(statusCodeToHttpsErrorCode(418), HttpsErrorCode.internal);
  });
}
