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

void main() {
  test('mock', () {
    ScheduleEventMock();
    SchedulerFunctionsMock();
    FirebaseFunctionsMock();
    FirestoreFunctionsMock();
  });
}
