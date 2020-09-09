import 'package:firebase_functions_interop/firebase_functions_interop.dart'
    as impl;
import 'package:tekartik_firebase_functions/firebase_functions.dart' as common;

import 'firebase_functions_node.dart';

class FirestoreFunctionsNode implements common.FirestoreFunctions {
  @override
  common.DocumentBuilder document(String path) =>
      DocumentBuilderNode(impl.functions.firestore.document(path));
}

class DocumentBuilderNode implements common.DocumentBuilder {
  final impl.DocumentBuilder implBuilder;

  DocumentBuilderNode(this.implBuilder);

  @override
  common.FirestoreFunction onWrite(
      common.ChangeEventHandler<common.DocumentSnapshot> handler) {
    return FirestoreFunctionNode(implBuilder.onWrite((data, context) {
      handler(ChangeNode(data), EventContextNode(context));
    }));
  }
}

class FirestoreFunctionNode extends FirebaseFunctionNode
    implements common.FirestoreFunction {
  final impl.CloudFunction implCloudFunction;

  FirestoreFunctionNode(this.implCloudFunction);

  @override
  dynamic get value => implCloudFunction;
}

class ChangeNode<T> implements common.Change<T> {
  final impl.Change implChange;

  ChangeNode(this.implChange);

  @override
  T get after => throw UnimplementedError();

  @override
  T get before => throw UnimplementedError();
}

class EventContextNode implements common.EventContext {
  final impl.EventContext implEventContext;

  EventContextNode(this.implEventContext);
}
