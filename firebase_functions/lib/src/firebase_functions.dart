// import 'package:tekartik_http/http_server.dart';

import 'dart:async';

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_functions/src/express_http_request.dart';
export 'package:tekartik_firebase_firestore/firestore.dart'
    show DocumentSnapshot;

abstract class FirebaseFunctions {
  HttpsFunctions get https;
  FirestoreFunctions get firestore;
  PubsubFunctions get pubsub;

  operator []=(String key, FirebaseFunction function);
}

typedef RequestHandler = void Function(ExpressHttpRequest request);

abstract class FirebaseFunction {}

/// Https function.
abstract class HttpsFunction implements FirebaseFunction {}

/// Firestore function.
abstract class FirestoreFunction implements FirebaseFunction {}

/// Pubsub function
abstract class PubsubFunction implements FirebaseFunction {}

abstract class FirestoreFunctions {
  DocumentBuilder document(String path);
}

abstract class HttpsFunctions {
  HttpsFunction onRequest(RequestHandler handler);
}

abstract class DocumentBuilder {
  FirestoreFunction onWrite(ChangeEventHandler<DocumentSnapshot> handler);
}

typedef ChangeEventHandler<T> = FutureOr<void> Function(
    Change<T> data, EventContext context);

/// The context in which an event occurred.
///
/// An EventContext describes:
///
///   * The time an event occurred.
///   * A unique identifier of the event.
///   * The resource on which the event occurred, if applicable.
///   * Authorization of the request that triggered the event, if applicable
///     and available.
abstract class EventContext {}

/// Container for events that change state, such as Realtime Database or
/// Cloud Firestore `onWrite` and `onUpdate`.
class Change<T> {
  Change(this.after, this.before);

  /// The state after the event.
  final T after;

  /// The state prior to the event.
  final T before;
}

//
// Pubsub
//

abstract class ScheduleContext {}

typedef ScheduleEventHandler = FutureOr<void> Function(ScheduleContext context);

abstract class ScheduleBuilder {
  /// Event handler that fires every time a schedule occurs.
  PubsubFunction onRun(ScheduleEventHandler handler);
}

abstract class PubsubFunctions {
  ScheduleBuilder schedule(String expression);
}
