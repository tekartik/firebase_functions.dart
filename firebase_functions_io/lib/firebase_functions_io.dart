import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
import 'package:tekartik_firebase_functions_io/src/firebase_functions_io.dart'
    as io;

export 'package:tekartik_firebase_functions/firebase_functions.dart';
export 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
export 'package:tekartik_firebase_functions_io/src/firebase_functions_io.dart'
    show serve;

/// Prefer service
FirebaseFunctionsHttp get firebaseFunctionsIo => io.firebaseFunctionsIo;

/// Default functions for io.
FirebaseFunctionsServiceHttp get firebaseFunctionsServiceIo =>
    firebaseFunctionsServiceHttpIo;

/// Default functions for io.
FirebaseFunctionsServiceHttp get firebaseFunctionsServiceHttpIo =>
    io.firebaseFunctionsServiceIo;
