import 'package:tekartik_firebase_functions/src/firebase_functions.dart';

import 'import.dart';

/// Firestore-triggered functions, the entry point to register handlers on
/// document paths.
abstract class FirestoreFunctions {
  /// Returns a [DocumentBuilder] targeting documents at [path].
  ///
  /// [path] can contain wildcard segments (e.g. `'users/{userId}'`) whose
  /// resolved values are exposed through [EventContext.params].
  DocumentBuilder document(String path);
}

/// Default mixin for [FirestoreFunctions] implementations; every member
/// throws an [UnimplementedError] unless overridden.
mixin FirestoreFunctionsDefaultMixin implements FirestoreFunctions {
  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  DocumentBuilder document(String path) =>
      throw UnimplementedError('FirestoreFunctions.document');
}

/// Builder used to register Firestore triggers on a specific document
/// path, obtained through [FirestoreFunctions.document].
abstract class DocumentBuilder {
  /// Registers [handler] to run whenever the document is created, updated
  /// or deleted, receiving both the before/after state as a
  /// [Change]<[DocumentSnapshot]>. Returns the resulting
  /// [FirestoreFunction].
  FirestoreFunction onWrite(ChangeEventHandler<DocumentSnapshot> handler);

  /// Registers [handler] to run whenever the document is created,
  /// receiving the created [DocumentSnapshot]. Returns the resulting
  /// [FirestoreFunction].
  FirestoreFunction onCreate(DataEventHandler<DocumentSnapshot> handler);

  /// Registers [handler] to run whenever the document is updated,
  /// receiving the before/after state as a [Change]<[DocumentSnapshot]>.
  /// Returns the resulting [FirestoreFunction].
  FirestoreFunction onUpdate(ChangeEventHandler<DocumentSnapshot> handler);

  /// Registers [handler] to run whenever the document is deleted,
  /// receiving the deleted [DocumentSnapshot]. Returns the resulting
  /// [FirestoreFunction].
  FirestoreFunction onDelete(DataEventHandler<DocumentSnapshot> handler);
}

/// Default mixin for [DocumentBuilder] implementations; every member
/// throws an [UnimplementedError] unless overridden.
mixin DocumentBuilderDefaultMixin implements DocumentBuilder {
  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  FirestoreFunction onCreate(DataEventHandler<DocumentSnapshot> handler) =>
      throw UnimplementedError('DocumentBuilderMock.onCreate');

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  FirestoreFunction onDelete(DataEventHandler<DocumentSnapshot> handler) =>
      throw UnimplementedError('DocumentBuilderMock.onDelete');

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  FirestoreFunction onUpdate(ChangeEventHandler<DocumentSnapshot> handler) =>
      throw UnimplementedError('DocumentBuilderMock.onUpdate');

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  FirestoreFunction onWrite(ChangeEventHandler<DocumentSnapshot> handler) =>
      throw UnimplementedError('DocumentBuilderMock.onWrite');
}

/// A function triggered by a Firestore document event, as created by
/// [DocumentBuilder].
abstract class FirestoreFunction implements FirebaseFunction {}

/// Signature of a handler for events carrying both a before and after
/// state (such as [DocumentBuilder.onWrite] and [DocumentBuilder.onUpdate]).
///
/// [data] carries the before/after value of type [T]. [context] describes
/// the event (timestamp, wildcard params, ...).
typedef ChangeEventHandler<T> =
    FutureOr<void> Function(Change<T> data, EventContext context);

/// Signature of a handler for events carrying a single state (such as
/// [DocumentBuilder.onCreate] and [DocumentBuilder.onDelete]).
///
/// [data] carries the value of type [T] created or deleted. [context]
/// describes the event (timestamp, wildcard params, ...).
typedef DataEventHandler<T> =
    FutureOr<void> Function(T data, EventContext context);

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

  /// The type of event that triggered the function (e.g.
  /// `'google.cloud.firestore.document.v1.written'`).
  String get eventType;

  /// Timestamp for the event.
  Timestamp get timestamp;
}

/// Container for events that change state, such as Realtime Database or
/// Cloud Firestore `onWrite` and `onUpdate`.
class Change<T> {
  /// Creates a [Change] wrapping the state [after] the event and the state
  /// [before] the event.
  Change(this.after, this.before);

  /// The state after the event.
  final T after;

  /// The state prior to the event.
  final T before;
}
