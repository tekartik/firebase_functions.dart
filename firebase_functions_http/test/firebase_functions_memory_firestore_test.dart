library;

import 'package:http/http.dart' as http;
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_memory.dart';
import 'package:tekartik_firebase_functions_http/src/import.dart';
import 'package:test/test.dart';

var _inPath = 'test/in';
var _outPath = 'test/out';

void main() {
  var firebaseFunctions = firebaseFunctionsMemory;
  var firestore = newFirestoreMemory();
  firebaseFunctions.init(firestore: firestore);
  var httpClientFactory = httpClientFactoryMemory;
  group('firebase_functions_memory', () {
    late HttpServer server;
    late http.Client client;
    setUpAll(() async {
      firebaseFunctions['trigger'] = firebaseFunctions.firestore
          .document('test/in')
          .onWrite((event, context) async {
            print('triggered $event $context');
            await firestore.doc(_outPath).set({'value': 1});
          });
      server = await firebaseFunctions.serveHttp(port: 0);
      client = httpClientFactory.newClient();
    });
    tearDownAll(() {
      server.close();
      client.close();
    });
    test('trigger', () async {
      await firestore.doc(_outPath).delete();
      await firestore.doc(_inPath).set({'value': 1});
      var completer = Completer<void>.sync();
      await for (var snapshot in firestore.doc(_outPath).onSnapshot()) {
        if (snapshot.exists) {
          completer.complete();
          break;
        }
      }
      await completer.future;
    });
  });
}
