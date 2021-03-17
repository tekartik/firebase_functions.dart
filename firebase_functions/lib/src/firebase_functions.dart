// import 'package:tekartik_http/http_server.dart';

import 'dart:async';

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_functions/src/express_http_request.dart';

export 'package:tekartik_firebase_firestore/firestore.dart'
    show DocumentSnapshot, Timestamp;

/// Global namespace for Firebase Cloud Functions functionality.
abstract class FirebaseFunctions {
  /// HTTPS functions.

  HttpsFunctions get https;

  /// Firestore functions.
  FirestoreFunctions get firestore;

  /// Pubsub functions.
  PubsubFunctions get pubsub;

  operator []=(String key, FirebaseFunction function);

  /// Configures the regions to which to deploy and run a function.
  ///
  /// For a list of valid values see https://firebase.google.com/docs/functions/locations
  FirebaseFunctions region(String region);

  /// Configures memory allocation and timeout for a function.
  FirebaseFunctions runWith(RuntimeOptions options);
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

/// Document builder.
abstract class DocumentBuilder {
  /// onWrite
  FirestoreFunction onWrite(ChangeEventHandler<DocumentSnapshot> handler);

  /// onCreate
  FirestoreFunction onCreate(DataEventHandler<DocumentSnapshot> handler);

  /// onUpdate
  FirestoreFunction onUpdate(ChangeEventHandler<DocumentSnapshot> handler);

  /// onDelete
  FirestoreFunction onDelete(DataEventHandler<DocumentSnapshot> handler);
}

/// Change event handler.
typedef ChangeEventHandler<T> = FutureOr<void> Function(
    Change<T> data, EventContext context);

/// Data event handler.
typedef DataEventHandler<T> = FutureOr<void> Function(
    T data, EventContext context);

/// The context in which an event occurred.
///
/// An EventContext describes:
///
///   * The time an event occurred.
///   * A unique identifier of the event.
///   * The resource on which the event occurred, if applicable.
///   * Authorization of the request that triggered the event, if applicable
///     and available.
abstract class EventContext {
  /// An object containing the values of the wildcards in the path parameter
  /// provided to the ref() method for a firestore/realtime database trigger.
  Map<String, String> get params;

  /// Type of event.
  String get eventType;

  /// Timestamp for the event.
  Timestamp get timestamp;
}

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

/// Schedule context.
abstract class ScheduleContext {}

/// Schedule event handler.
typedef ScheduleEventHandler = FutureOr<void> Function(ScheduleContext context);

/// Schedule builder.
abstract class ScheduleBuilder {
  /// Event handler that fires every time a schedule occurs.
  PubsubFunction onRun(ScheduleEventHandler handler);
}

/// Pubsub functions.
abstract class PubsubFunctions {
  ScheduleBuilder schedule(String expression);
}

/// RunWith options
class RuntimeOptions {
  /// Timeout for the function in seconds.
  final int? timeoutSeconds;

  /// Amount of memory to allocate to the function.
  ///
  /// Valid values are: '128MB', '256MB', '512MB', '1GB', and '2GB'.
  final String? memory;

  RuntimeOptions({this.timeoutSeconds, this.memory});
}

/// Belgium location
const regionBelgium = 'europe-west1';

/// Memory
const runtimeOptionsMemory128MB = '128MB';
const runtimeOptionsMemory256MB = '256MB';
const runtimeOptionsMemory512MB = '512MB';
const runtimeOptionsMemory1GB = '1GB';
const runtimeOptionsMemory2GB = '2GB';
