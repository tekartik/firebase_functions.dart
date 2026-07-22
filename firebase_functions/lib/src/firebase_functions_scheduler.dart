import 'package:tekartik_firebase_functions/src/firebase_functions.dart';

import 'import.dart';

/// Signature of a handler invoked when a Cloud Scheduler job configured
/// through [SchedulerFunctions.onSchedule] fires, receiving the triggering
/// [ScheduleEvent].
typedef ScheduleHandler = FutureOr<void> Function(ScheduleEvent data);

/// The event delivered to a [ScheduleHandler] when a scheduled function
/// fires.
abstract class ScheduleEvent {
  /// The Cloud Scheduler job name, populated via the
  /// `X-CloudScheduler-JobName` header.
  ///
  /// `null` if the function was invoked manually rather than by the
  /// scheduler.
  String? get jobName;

  /// The job's scheduled trigger time.
  ///
  /// For Cloud Scheduler jobs specified in unix-cron format, this is the
  /// job schedule time in RFC3339 UTC "Zulu" format, populated via the
  /// `X-CloudScheduler-ScheduleTime` header. If the schedule was triggered
  /// manually, this is the function execution time instead. May be `null`
  /// if unavailable.
  String? get scheduleTime;
}

/// Scheduler-based (Cloud Scheduler) functions, the entry point to
/// register functions that run on a recurring schedule.
abstract class SchedulerFunctions {
  /// Registers [handler] to run according to [scheduleOptions] (the cron
  /// expression, timezone and deployment options).
  ///
  /// Returns the resulting [ScheduleFunction].
  ScheduleFunction onSchedule(
    ScheduleOptions scheduleOptions,
    ScheduleHandler handler,
  );
}

/// Options for a scheduled function, passed to
/// [SchedulerFunctions.onSchedule].
class ScheduleOptions extends GlobalOptions {
  /// The schedule, in Unix Crontab or AppEngine syntax (e.g.
  /// `'every 5 minutes'` or `'0 */2 * * *'`).
  final String schedule;

  /// The timezone the schedule executes in (e.g. `'Europe/Paris'`).
  ///
  /// `null`/omitted uses the platform default timezone (typically UTC).
  final String? timeZone;

  /// Creates the options for a scheduled function.
  ///
  /// [schedule] is required. [timeZone] and the inherited [GlobalOptions]
  /// parameters are optional; a `null`/omitted value leaves the
  /// corresponding setting at its platform default.
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

/// Default mixin for [SchedulerFunctions] implementations; every member
/// throws an [UnimplementedError] unless overridden.
mixin SchedulerFunctionsDefaultMixin implements SchedulerFunctions {
  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  ScheduleFunction onSchedule(
    ScheduleOptions scheduleOptions,
    ScheduleHandler handler,
  ) {
    throw UnimplementedError('SchedulerFunctions.onSchedule');
  }
}

/// A function triggered by a Cloud Scheduler schedule, as created by
/// [SchedulerFunctions.onSchedule].
abstract class ScheduleFunction implements FirebaseFunction {}

/// Default mixin for [ScheduleEvent] implementations; every member throws
/// an [UnimplementedError] unless overridden.
mixin SchedulerEventDefaultMixin implements ScheduleEvent {
  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  String? get jobName => throw UnimplementedError('ScheduleEvent.jobName');

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  String? get scheduleTime =>
      throw UnimplementedError('ScheduleEvent.scheduleTime');
}
