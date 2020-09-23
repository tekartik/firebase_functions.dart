import 'package:firebase_functions_interop/firebase_functions_interop.dart'
    as impl;
import 'package:tekartik_firebase_firestore_node/src/firestore_node.dart' // ignore: implementation_imports
    as firestore_node;
import 'package:tekartik_firebase_firestore/firestore.dart' as firestore;
import 'package:tekartik_firebase_functions/firebase_functions.dart' as common;
import 'package:firebase_admin_interop/firebase_admin_interop.dart' as node;
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
      handler(DocumentSnapshotChangeNode(data), EventContextNode(context));
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

abstract class ChangeNode<T> implements common.Change<T> {
  final impl.Change implChange;

  ChangeNode(this.implChange);

  @override
  T get after => throw UnimplementedError('ChangeNode.after');

  @override
  T get before => throw UnimplementedError('ChangeNode.before');
}

class DocumentSnapshotChangeNode
    extends ChangeNode<firestore.DocumentSnapshot> {
  DocumentSnapshotChangeNode(impl.Change implChange) : super(implChange);

  @override
  firestore.DocumentSnapshot get after => firestore_node.DocumentSnapshotNode(
      implChange.after as node.DocumentSnapshot);

  @override
  firestore.DocumentSnapshot get before => firestore_node.DocumentSnapshotNode(
      implChange.after as node.DocumentSnapshot);
}

class EventContextNode implements common.EventContext {
  final impl.EventContext implEventContext;

  EventContextNode(this.implEventContext);
}
