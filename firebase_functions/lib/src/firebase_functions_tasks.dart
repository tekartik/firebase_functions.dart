import 'dart:async';
import 'dart:math';

/// A task delivered to its task queue function (a Cloud Tasks queue is named
/// after its function).
abstract class TaskQueueRequest {
  /// The data given when the task was enqueued.
  Object? get data;

  /// The id of the task (generated when none was given at enqueue time).
  String get id;

  /// The name of the queue, i.e. the function name (Cloud Tasks may send
  /// a longer internal queue name, check with `contains`).
  String get queueName;

  /// How many times the task has been retried (0 on the first attempt).
  int get retryCount;

  /// How many times the task has been executed, failed attempts included
  /// (0 on the first attempt).
  int get executionCount;
}

/// A simple [TaskQueueRequest], for implementations and tests.
class TaskQueueRequestData implements TaskQueueRequest {
  @override
  final Object? data;
  @override
  final String id;
  @override
  final String queueName;
  @override
  final int retryCount;
  @override
  final int executionCount;

  /// A task request.
  const TaskQueueRequestData({
    required this.data,
    required this.id,
    required this.queueName,
    this.retryCount = 0,
    this.executionCount = 0,
  });

  @override
  String toString() =>
      'TaskQueueRequest($queueName, $id, retry $retryCount, data $data)';
}

/// Handles a task dispatched to its task queue function. A throw asks for a
/// retry (up to the max attempts of the queue).
typedef TaskQueueHandler = Future<void> Function(TaskQueueRequest request);

/// Options used when enqueuing a task, see [TaskQueue.enqueue].
class TaskQueueEnqueueOptions {
  /// Delay before the task is dispatched (exclusive with [scheduleTime]).
  final Duration? scheduleDelay;

  /// When the task is dispatched (exclusive with [scheduleDelay]).
  final DateTime? scheduleTime;

  /// The task id: a second task with the same id is refused (while the
  /// first one is known), which makes an enqueue idempotent.
  final String? id;

  /// Overrides the url the task is sent to (admin sdk only, the emulator
  /// cannot resolve the production function url).
  final String? uri;

  /// Options used when enqueuing a task.
  const TaskQueueEnqueueOptions({
    this.scheduleDelay,
    this.scheduleTime,
    this.id,
    this.uri,
  }) : assert(
         scheduleDelay == null || scheduleTime == null,
         'scheduleDelay and scheduleTime are exclusive',
       );

  /// Throws an [ArgumentError] when both [scheduleDelay] and [scheduleTime]
  /// are set (the const constructor only asserts it).
  void validate() {
    if (scheduleDelay != null && scheduleTime != null) {
      throw ArgumentError('scheduleDelay and scheduleTime are exclusive');
    }
  }
}

/// The queue of a task queue function, to enqueue tasks to it.
abstract class TaskQueue {
  /// The function the tasks are dispatched to (the queue name).
  String get functionName;

  /// Enqueue a task carrying [data] (json encodable), dispatched later to
  /// the function. Completes once the task is enqueued, not run.
  Future<void> enqueue(
    Map<String, Object?> data, {
    TaskQueueEnqueueOptions? options,
  });
}

/// Gives the queues of the task queue functions of a project.
abstract class TaskQueueService {
  /// The queue of the task queue function [functionName], deployed in
  /// [region] (the default region of the implementation when null).
  TaskQueue taskQueue(String functionName, {String? region});
}

/// A task queue service running everything in process: the handlers are
/// registered with [onTaskDispatched], the enqueued tasks dispatched to them
/// asynchronously (timers), retried on a throw up to their max attempts.
///
/// For tests and in memory backends; [waitForTasks] waits for the tasks to
/// be done. The error of a task whose last attempt failed is not rethrown,
/// it is kept in [taskErrors].
class TaskQueueServiceMemory implements TaskQueueService {
  final _handlers = <String, _MemoryTaskQueueFunction>{};
  final _pending = <_MemoryTask>{};
  final _knownIds = <String>{};
  final _taskErrors = <Object>[];
  var _running = 0;
  var _idCounter = 0;
  final _random = Random();
  Completer<void>? _idle;
  var _closed = false;

  /// A memory task queue service.
  TaskQueueServiceMemory();

  /// Registers [handler] for the queue of [functionName], tasks are tried
  /// up to [maxAttempts] times.
  void onTaskDispatched(
    String functionName,
    TaskQueueHandler handler, {
    int maxAttempts = 1,
  }) {
    _handlers[functionName] = _MemoryTaskQueueFunction(
      handler,
      maxAttempts: max(1, maxAttempts),
    );
  }

  /// The errors of the tasks whose last attempt failed.
  List<Object> get taskErrors => List.unmodifiable(_taskErrors);

  /// True when no task is pending (scheduled) nor running.
  bool get isIdle => _pending.isEmpty && _running == 0;

  @override
  TaskQueue taskQueue(String functionName, {String? region}) =>
      _MemoryTaskQueue(this, functionName);

  /// Completes when no task is pending nor running, including the tasks
  /// enqueued by running tasks.
  Future<void> waitForTasks() async {
    while (!isIdle) {
      await (_idle ??= Completer<void>()).future;
    }
  }

  /// Cancels the pending tasks, refuses new ones.
  Future<void> close() async {
    _closed = true;
    for (var task in _pending.toList()) {
      task.timer?.cancel();
    }
    _pending.clear();
    _checkIdle();
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${(++_idCounter).toRadixString(36)}'
      '${_random.nextInt(1 << 30).toRadixString(36)}';

  Future<void> _enqueue(
    String functionName,
    Map<String, Object?> data,
    TaskQueueEnqueueOptions? options,
  ) async {
    options?.validate();
    if (_closed) {
      throw StateError('TaskQueueServiceMemory closed');
    }
    var function = _handlers[functionName];
    if (function == null) {
      throw StateError('No task queue function $functionName');
    }
    var id = options?.id ?? _newId();
    if (!_knownIds.add(id)) {
      throw StateError('Task $id already exists in $functionName');
    }
    var task = _MemoryTask(
      function: function,
      queueName: functionName,
      id: id,
      data: data,
    );
    var delay = options?.scheduleDelay;
    var scheduleTime = options?.scheduleTime;
    if (scheduleTime != null) {
      delay = scheduleTime.difference(DateTime.now());
    }
    _schedule(task, delay ?? Duration.zero);
  }

  void _schedule(_MemoryTask task, Duration delay) {
    _pending.add(task);
    task.timer = Timer(delay.isNegative ? Duration.zero : delay, () {
      _pending.remove(task);
      _running++;
      unawaited(_run(task));
    });
  }

  Future<void> _run(_MemoryTask task) async {
    try {
      await task.function.handler(
        TaskQueueRequestData(
          data: task.data,
          id: task.id,
          queueName: task.queueName,
          retryCount: task.executionCount,
          executionCount: task.executionCount,
        ),
      );
    } catch (e) {
      task.executionCount++;
      if (!_closed && task.executionCount < task.function.maxAttempts) {
        _schedule(task, Duration.zero);
      } else {
        _taskErrors.add(e);
      }
    } finally {
      _running--;
      _checkIdle();
    }
  }

  void _checkIdle() {
    if (isIdle) {
      var idle = _idle;
      _idle = null;
      idle?.complete();
    }
  }
}

class _MemoryTaskQueueFunction {
  final TaskQueueHandler handler;
  final int maxAttempts;

  _MemoryTaskQueueFunction(this.handler, {required this.maxAttempts});
}

class _MemoryTask {
  final _MemoryTaskQueueFunction function;
  final String queueName;
  final String id;
  final Map<String, Object?> data;
  var executionCount = 0;
  Timer? timer;

  _MemoryTask({
    required this.function,
    required this.queueName,
    required this.id,
    required this.data,
  });
}

class _MemoryTaskQueue implements TaskQueue {
  final TaskQueueServiceMemory service;
  @override
  final String functionName;

  _MemoryTaskQueue(this.service, this.functionName);

  @override
  Future<void> enqueue(
    Map<String, Object?> data, {
    TaskQueueEnqueueOptions? options,
  }) => service._enqueue(functionName, data, options);
}
