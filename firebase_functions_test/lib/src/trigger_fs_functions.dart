import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/json_utils.dart';
import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';

import 'import.dart';

const functionSetInTrigger = 'setintriggerv1';
const functionGetOutTrigger = 'getouttriggerv1';
const functionOnTrigger = 'ontriggerv1';

const triggerPath = 'test/ffprv/trigger/in';
const triggerPathOut = 'test/ffprv/trigger/out';

class FirestoreTriggerServerTestSetup {
  final Version version;
  final FirebaseFunctions functions;
  final Firestore firestore;

  FirestoreTriggerServerTestSetup({
    required this.functions,
    required this.firestore,
    required this.version,
  });

  HttpsFunction get setInTriggerFunction => functions.https.onRequestV2(
    HttpsOptions(cors: true, region: regionBelgium),
    setInTriggerHandler,
  );

  HttpsFunction get getOutTriggerFunction => functions.https.onRequestV2(
    HttpsOptions(cors: true, region: regionBelgium),
    getOutTriggerHandler,
  );

  FirestoreFunction get triggerFunction =>
      functions.firestore.document(triggerPath).onWrite(triggerHandler);

  Future<void> setInTriggerHandler(ExpressHttpRequest request) async {
    var doc = await firestore.doc(triggerPath).get();
    var value = 1;
    if (doc.exists) {
      var raw = doc.data['value'];
      if (raw is int) {
        value = raw + 1;
      }
    }
    try {
      await firestore.doc(triggerPath).set(<String, Object?>{
        'value': value,
        'timestamp': Timestamp.now(),
      });
    } catch (_) {
      await firestore.doc(triggerPath).set(<String, Object?>{
        'value': value,
        'timestampText': Timestamp.now().toIso8601String(),
      });
    }
    await getOutTriggerHandler(request);
  }

  Future<void> getOutTriggerHandler(ExpressHttpRequest request) async {
    var res = request.response;
    var doc = await firestore.doc(triggerPath).get();
    var docOut = await firestore.doc(triggerPathOut).get();
    var jsonIn = doc.exists
        ? documentDataValueToJson(doc.data)
        : {'error': 'not found'};
    var jsonOut = docOut.exists
        ? documentDataValueToJson(docOut.data)
        : {'error': 'not found'};
    await res.send({
      'in': jsonIn,
      'out': jsonOut,
      'version': version.toString(),
    });
  }

  Future<void> triggerHandler(
    Change<DocumentSnapshot> change,
    EventContext eventContext,
  ) async {
    print('triggerHandler');
    print('Tracking change $change');
    var changedDoc = change.after;
    int? value;
    if (changedDoc.exists) {
      var data = changedDoc.data;
      var raw = data['value'];
      if (raw is int) {
        value = raw;
      }
    }
    try {
      await firestore.doc(triggerPathOut).set(<String, Object?>{
        'value': value,
        'timestamp': Timestamp.now(),
        'triggerVersion': version.toString(),
      }); //FieldValue.serverTimestamp});
    } catch (e) {
      print('error $e updating timestamp $triggerPathOut');
      try {
        await firestore.doc(triggerPathOut).set(<String, Object?>{
          'value': value,
          'datetime': DateTime.now(),
          'triggerVersion': version.toString(),
        }); //FieldValue.serverTimestamp});
        print('error $e updating datetime $triggerPathOut');
      } catch (e) {
        try {
          await firestore.doc(triggerPathOut).set(<String, Object?>{
            'value': value,
            'timestampText': Timestamp.now().toIso8601String(),
            'triggerVersion': version.toString(),
          }); //FieldValue.serverTimestamp});
        } catch (e) {
          print('error $e updating $triggerPathOut');
        }
      }
    }

    print('Tracking change $change');
  }

  void initFunctionsFs() {
    var globalOptions = GlobalOptions(region: regionBelgium);
    if (functions is FirebaseFunctionsHttp) {
      (functions as FirebaseFunctionsHttp).init(firestore: firestore);
    }
    functions.globalOptions = globalOptions;

    functions[functionSetInTrigger] = setInTriggerFunction;
    functions[functionGetOutTrigger] = getOutTriggerFunction;
    functions[functionOnTrigger] = triggerFunction;
  }
}
