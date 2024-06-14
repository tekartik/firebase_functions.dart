import 'package:tekartik_firebase_functions/firebase_functions.dart';

class SchedulerFunctionsMock
    with SchedulerFunctionsDefaultMixin
    implements SchedulerFunctions {}

class ScheduleEventMock
    with SchedulerEventDefaultMixin
    implements ScheduleEvent {}
