import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';

import 'firebase_functions_http.dart';

class FirestoreFunctionsHttp with FirestoreFunctionsDefaultMixin {
  final FirebaseFunctionsHttpBase httpBase;

  FirestoreFunctionsHttp(this.httpBase);

  @override
  DocumentBuilder document(String path) => DocumentBuilderHttp(this, path);
}

class DocumentBuilderHttp with DocumentBuilderDefaultMixin {
  final FirestoreFunctionsHttp firestoreFunctionsHttp;
  final String path;

  Firestore get firestore => firestoreFunctionsHttp.httpBase.firebaseFirestore!;

  DocumentBuilderHttp(this.firestoreFunctionsHttp, this.path);

  @override
  FirestoreFunction onWrite(ChangeEventHandler<DocumentSnapshot> handler) {
    return FirestoreFunctionHttp(this, handler);
  }
}

class FirestoreFunctionHttp implements FirestoreFunction {
  final DocumentBuilderHttp documentBuilder;
  final ChangeEventHandler<DocumentSnapshot> handler;

  Firestore get firestore => documentBuilder.firestore;

  String get path => documentBuilder.path;

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
      handler(Change<DocumentSnapshot>(newValue, previousValue),
          EventContextHttp());
    });
  }
}

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
