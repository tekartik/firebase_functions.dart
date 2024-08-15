import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:test/test.dart';

class SchedulerFunctionsMock
    with SchedulerFunctionsDefaultMixin
    implements SchedulerFunctions {}

class ScheduleEventMock
    with SchedulerEventDefaultMixin
    implements ScheduleEvent {}

class FirestoreFunctionsMock
    with FirestoreFunctionsDefaultMixin
    implements FirestoreFunctions {}

class FirebaseFunctionsMock
    with FirebaseFunctionsDefaultMixin
    implements FirebaseFunctions {}

class DocumentBuilderMock
    with DocumentBuilderDefaultMixin
    implements DocumentBuilder {}

class CallRequestMock with CallRequestMixin {
  @override
  final Object? data;
  CallRequestMock({this.data});
}

void main() {
  test('mock', () {
    ScheduleEventMock();
    SchedulerFunctionsMock();
    FirebaseFunctionsMock();
    FirestoreFunctionsMock();
  });
  test('call_request', () {
    var request = CallRequestMock();
    expect(request.data, null);
    request = CallRequestMock(data: <String, Object?>{});
    expect(request.dataAsText, '{}');
    request = CallRequestMock(data: '{}');
    expect(request.dataAsMap, <String, Object?>{});
  });
}
