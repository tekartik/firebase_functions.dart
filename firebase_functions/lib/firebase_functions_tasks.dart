/// Task queue functions (Cloud Tasks): enqueue tasks to a function's queue
/// ([TaskQueueService], [TaskQueue]) and handle them ([TaskQueueHandler],
/// [TaskQueueRequest]), with an in process implementation
/// ([TaskQueueServiceMemory]) for tests and in memory backends.
///
/// Not exported by `firebase_functions.dart`: its names would clash with the
/// native `firebase_functions` ones in a dart3 `bin/server.dart`.
library;

export 'package:tekartik_firebase_functions/src/firebase_functions_tasks.dart'
    show
        TaskQueueRequest,
        TaskQueueRequestData,
        TaskQueueHandler,
        TaskQueueEnqueueOptions,
        TaskQueue,
        TaskQueueService,
        TaskQueueServiceMemory;
