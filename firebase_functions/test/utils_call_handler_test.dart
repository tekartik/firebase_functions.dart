import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tekartik_firebase_functions/utils.dart';
import 'package:tekartik_http/http_memory.dart';
import 'package:test/test.dart';

/// A request whose response records what is sent.
class _FakeRequest implements ExpressHttpRequest {
  @override
  final Object? body;
  @override
  final _FakeResponse response = _FakeResponse();

  _FakeRequest(this.body);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeResponse implements ExpressHttpResponse {
  @override
  var statusCode = 200;
  @override
  final HttpHeaders headers = HttpHeadersMemory();
  Object? sent;
  var sendCount = 0;

  @override
  Future send([Object? body]) async {
    sent = body;
    sendCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('handleWithCallHandler', () {
    Future<_FakeResponse> handle(CallHandler handler) async {
      var request = _FakeRequest(Uint8List.fromList(utf8.encode('{"a":1}')));
      await request.handleWithCallHandler(handler);
      return request.response;
    }

    test('result', () async {
      var response = await handle((request) => request.getRequestAsMap());
      expect(response.statusCode, 200);
      expect(jsonDecode(response.sent as String), {'a': 1});
    });

    test('error with non JSON details (anyExceptionToHttpsError)', () async {
      var response = await handle((request) {
        try {
          throw StateError('downstream failed');
        } catch (e, st) {
          throw anyExceptionToHttpsError(e, stackTrace: st);
        }
      });
      // The error response is sent anyway, the details as text.
      expect(response.sendCount, 1);
      expect(response.statusCode, 500);
      var error = (jsonDecode(response.sent as String) as Map)['error'] as Map;
      expect(error['status'], 'INTERNAL');
      expect(error['message'], contains('downstream failed'));
      expect(error['details'], isA<String>());
    });
  });
}
