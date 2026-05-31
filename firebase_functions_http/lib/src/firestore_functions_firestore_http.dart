import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';

import 'firebase_functions_http.dart';

/// Firestore functions HTTP implementation.
class FirestoreFunctionsHttp with FirestoreFunctionsDefaultMixin {
  /// The associated HTTP Firebase Functions instance.
  final FirebaseFunctionsHttpBase httpBase;

  /// Creates a new [FirestoreFunctionsHttp] instance.
  FirestoreFunctionsHttp(this.httpBase);

  @override
  DocumentBuilder document(String path) => DocumentBuilderHttp(this, path);
}

/// Document builder HTTP implementation.
class DocumentBuilderHttp with DocumentBuilderDefaultMixin {
  /// The associated Firestore functions instance.
  final FirestoreFunctionsHttp firestoreFunctionsHttp;

  /// The document path.
  final String path;

  /// The Firestore database instance.
  Firestore get firestore =>
      firestoreFunctionsHttp.httpBase.firebaseFirestoreOrThrow;

  /// Creates a new [DocumentBuilderHttp] instance.
  DocumentBuilderHttp(this.firestoreFunctionsHttp, this.path);

  @override
  FirestoreFunction onWrite(ChangeEventHandler<DocumentSnapshot> handler) {
    return FirestoreFunctionHttp(this, handler);
  }
}

/// Firestore function HTTP implementation.
class FirestoreFunctionHttp implements FirestoreFunction {
  /// The document builder.
  final DocumentBuilderHttp documentBuilder;

  /// The change event handler.
  final ChangeEventHandler<DocumentSnapshot> handler;

  /// The Firestore instance.
  Firestore get firestore => documentBuilder.firestore;

  /// The document path.
  String get path => documentBuilder.path;

  /// Creates a new [FirestoreFunctionHttp] instance and listens for snapshots.
  FirestoreFunctionHttp(this.documentBuilder, this.handler) {
    DocumentSnapshot? lastValue;
    firestore.doc(path).onSnapshot().listen((snapshot) {
      if (lastValue == null) {
        lastValue = snapshot;
        return;
      }
      var newValue = snapshot;
      var previousValue = lastValue!;
      lastValue = newValue;
      handler(
        Change<DocumentSnapshot>(newValue, previousValue),
        EventContextHttp(),
      );
    });
  }
}

/// Event context HTTP implementation.
class EventContextHttp implements EventContext {
  @override
  // TODO: implement eventType
  String get eventType => throw UnimplementedError();

  @override
  // TODO: implement params
  Map<String, String> get params => throw UnimplementedError();

  @override
  // TODO: implement timestamp
  Timestamp get timestamp => throw UnimplementedError();
}
