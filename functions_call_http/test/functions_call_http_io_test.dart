library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_functions_http/src/import.dart';
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

import 'functions_call_http_memory_test.dart';

Future<Object?> callHandler(CallRequest request) async {
  return {'uid': request.context.auth?.uid};
}

void main() {
  var dummyProjectId = 'dummyproject';
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: dummyProjectId),
  );

  var authService = FirebaseAuthServiceSembast(
    databaseFactory: newDatabaseFactoryMemory(),
  );
  var httpClientFactory = httpClientFactoryIo;
  var firebaseFunctions = firebaseFunctionsServiceHttpIo.functions(app);
  var firebaseAuth = authService.auth(app);

  group('firebase_functions_call_http_io', () {
    testHttp(
      firebaseAuth: firebaseAuth,
      firebaseFunctions: firebaseFunctions,
      httpClientFactory: httpClientFactory,
      app: app,
    );
  });
}
