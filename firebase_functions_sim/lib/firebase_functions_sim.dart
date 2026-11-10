/// The functions implementation of the Tekartik firebase simulator:
/// [firebaseFunctionsServiceSim] (today the `dart:io` service of
/// `tekartik_firebase_functions_io`). Re-exports the functions api, the http
/// and the io libraries. Dart VM only.
library;

import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart'
    as io;
export 'package:tekartik_firebase_functions/firebase_functions.dart';
export 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
export 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';

/// The sim functions service: the `dart:io` service
/// (`firebaseFunctionsServiceIo`), one `FirebaseFunctionsHttp` per app.
FirebaseFunctionsServiceHttp get firebaseFunctionsServiceSim =>
    io.firebaseFunctionsServiceIo;
