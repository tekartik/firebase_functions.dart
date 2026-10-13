import 'dart:async';

import 'package:tekartik_firebase_functions/firebase_functions_tasks.dart';
import 'package:test/test.dart';

void main() {
  group('TaskQueueServiceMemory', () {
    late TaskQueueServiceMemory service;
    setUp(() {
      service = TaskQueueServiceMemory();
    });
    tearDown(() async {
      await service.close();
    });

    test('enqueue and dispatch', () async {
      var requests = <TaskQueueRequest>[];
      service.onTaskDispatched('task1', (request) async {
        requests.add(request);
      });
      var queue = service.taskQueue('task1');
      expect(queue.functionName, 'task1');
      await queue.enqueue({'value': 1});
      // Enqueued, not run yet.
      expect(requests, isEmpty);
      expect(service.isIdle, isFalse);
      await service.waitForTasks();
      expect(service.isIdle, isTrue);
      expect(requests, hasLength(1));
      var request = requests.first;
      expect(request.data, {'value': 1});
      expect(request.queueName, 'task1');
      expect(request.id, isNotEmpty);
      expect(request.retryCount, 0);
      expect(request.executionCount, 0);
    });

    test('waitForTasks idle', () async {
      await service.waitForTasks();
    });

    test('delay and schedule time', () async {
      var values = <Object?>[];
      service.onTaskDispatched('task1', (request) async {
        values.add((request.data as Map)['value']);
      });
      var queue = service.taskQueue('task1');
      var sw = Stopwatch()..start();
      await queue.enqueue(
        {'value': 2},
        options: const TaskQueueEnqueueOptions(
          scheduleDelay: Duration(milliseconds: 50),
        ),
      );
      await queue.enqueue(
        {'value': 1},
        options: TaskQueueEnqueueOptions(
          scheduleTime: DateTime.now().add(const Duration(milliseconds: 10)),
        ),
      );
      await service.waitForTasks();
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(40));
      expect(values, [1, 2]);
      expect(
        () => queue.enqueue(
          {},
          // ignore: prefer_const_constructors
          options: TaskQueueEnqueueOptions(
            scheduleDelay: Duration.zero,
            scheduleTime: DateTime.now(),
          ),
        ),
        throwsA(anyOf(isA<ArgumentError>(), isA<AssertionError>())),
      );
    });

    test('retry', () async {
      var requests = <TaskQueueRequest>[];
      service.onTaskDispatched('task1', (request) async {
        requests.add(request);
        if (request.retryCount < 2) {
          throw StateError('fail ${request.retryCount}');
        }
      }, maxAttempts: 3);
      await service.taskQueue('task1').enqueue({});
      await service.waitForTasks();
      expect(requests.map((r) => r.retryCount), [0, 1, 2]);
      expect(requests.map((r) => r.executionCount), [0, 1, 2]);
      expect(requests.map((r) => r.id).toSet(), hasLength(1));
      expect(service.taskErrors, isEmpty);
    });

    test('last attempt error recorded', () async {
      var count = 0;
      service.onTaskDispatched('task1', (request) async {
        count++;
        throw StateError('always');
      }, maxAttempts: 2);
      await service.taskQueue('task1').enqueue({});
      await service.waitForTasks();
      expect(count, 2);
      expect(service.taskErrors, hasLength(1));
    });

    test('id duplicate', () async {
      service.onTaskDispatched('task1', (request) async {});
      var queue = service.taskQueue('task1');
      await queue.enqueue({}, options: const TaskQueueEnqueueOptions(id: 'a'));
      await expectLater(
        queue.enqueue({}, options: const TaskQueueEnqueueOptions(id: 'a')),
        throwsStateError,
      );
      await service.waitForTasks();
      // Still known once run (Cloud Tasks keeps the name for a while).
      await expectLater(
        queue.enqueue({}, options: const TaskQueueEnqueueOptions(id: 'a')),
        throwsStateError,
      );
    });

    test('unregistered', () async {
      await expectLater(
        service.taskQueue('unknown').enqueue({}),
        throwsStateError,
      );
    });

    test('chained tasks', () async {
      var values = <int>[];
      service.onTaskDispatched('chain', (request) async {
        var value = (request.data as Map)['value'] as int;
        values.add(value);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        if (value < 3) {
          await service.taskQueue('chain').enqueue({'value': value + 1});
        }
      });
      await service.taskQueue('chain').enqueue({'value': 1});
      await service.waitForTasks();
      expect(values, [1, 2, 3]);
    });

    test('close', () async {
      var count = 0;
      service.onTaskDispatched('task1', (request) async {
        count++;
      });
      await service
          .taskQueue('task1')
          .enqueue(
            {},
            options: const TaskQueueEnqueueOptions(
              scheduleDelay: Duration(milliseconds: 20),
            ),
          );
      await service.close();
      await service.waitForTasks();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(count, 0);
      await expectLater(
        service.taskQueue('task1').enqueue({}),
        throwsStateError,
      );
    });
  });
}
