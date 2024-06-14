import 'package:tekartik_firebase_functions/src/firebase_functions.dart';

import 'import.dart';

/// Https request handler
typedef ScheduleHandler = FutureOr<void> Function(ScheduleEvent data);

abstract class ScheduleEvent {
  /// jobName	string
  /// The Cloud Scheduler job name. Populated via the X-CloudScheduler-JobName header.
  /// If invoked manually, this field is undefined.
  String? get jobName;

  /// scheduleTime	string
  /// For Cloud Scheduler jobs specified in the unix-cron format,
  /// this is the job schedule time in RFC3339 UTC "Zulu" format. Populated via the X-CloudScheduler-ScheduleTime header.
  /// If the schedule is manually triggered, this field will be the function execution time.
  String? get scheduleTime;
}

abstract class SchedulerFunctions {
  /// HTTPS request
  ScheduleFunction onSchedule(
      ScheduleOptions scheduleOptions, ScheduleHandler handler);
}

class ScheduleOptions extends GlobalOptions {
  /// The schedule, in Unix Crontab or AppEngine syntax.
  ///
  /// schedule: string
  final String schedule;

  /// The timezone that the schedule executes in.
  ///
  /// timeZone?: timezone | Expression<string> | ResetValue
  final String? timeZone;

  ScheduleOptions({
    required this.schedule,
    this.timeZone,
    super.timeoutSeconds,
    super.memory,
    super.region,
    super.regions,
    super.concurrency,
  });
}

mixin SchedulerFunctionsDefaultMixin implements SchedulerFunctions {
  @override
  ScheduleFunction onSchedule(
      ScheduleOptions scheduleOptions, ScheduleHandler handler) {
    throw UnimplementedError('SchedulerFunctions.onSchedule');
  }
}

/// Scheduler function.
abstract class ScheduleFunction implements FirebaseFunction {}

mixin SchedulerEventDefaultMixin implements ScheduleEvent {
  @override
  String? get jobName => throw UnimplementedError('ScheduleEvent.jobName');

  @override
  String? get scheduleTime =>
      throw UnimplementedError('ScheduleEvent.scheduleTime');
}
