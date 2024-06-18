import 'package:tekartik_firebase_functions/src/firebase_functions.dart';

import 'import.dart';

/// Firestore functions.
abstract class FirestoreFunctions {
  DocumentBuilder document(String path);
}

mixin FirestoreFunctionsDefaultMixin implements FirestoreFunctions {
  @override
  DocumentBuilder document(String path) =>
      throw UnimplementedError('FirestoreFunctions.document');
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

mixin DocumentBuilderDefaultMixin implements DocumentBuilder {
  @override
  FirestoreFunction onCreate(DataEventHandler<DocumentSnapshot> handler) =>
      throw UnimplementedError('DocumentBuilderMock.onCreate');

  @override
  FirestoreFunction onDelete(DataEventHandler<DocumentSnapshot> handler) =>
      throw UnimplementedError('DocumentBuilderMock.onDelete');

  @override
  FirestoreFunction onUpdate(ChangeEventHandler<DocumentSnapshot> handler) =>
      throw UnimplementedError('DocumentBuilderMock.onUpdate');

  @override
  FirestoreFunction onWrite(ChangeEventHandler<DocumentSnapshot> handler) =>
      throw UnimplementedError('DocumentBuilderMock.onWrite');
}

/// Firestore function.
abstract class FirestoreFunction implements FirebaseFunction {}

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
