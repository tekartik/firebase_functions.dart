import 'package:tekartik_firebase_functions/firebase_functions.dart';
import 'package:test/test.dart';

class SchedulerFunctionsMock
    with SchedulerFunctionsDefaultMixin
    implements SchedulerFunctions {}

class ScheduleEventMock
    with SchedulerEventDefaultMixin
    implements ScheduleEvent {}

void main() {
  test('mock', () {
    ScheduleEventMock();
    SchedulerFunctionsMock();
  });
}
