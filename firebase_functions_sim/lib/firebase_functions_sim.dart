import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart'
    as io;
export 'package:tekartik_firebase_functions/firebase_functions.dart';
export 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
export 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';

/// Default functions service memory.
FirebaseFunctionsServiceHttp get firebaseFunctionsServiceSim =>
    io.firebaseFunctionsServiceIo;
