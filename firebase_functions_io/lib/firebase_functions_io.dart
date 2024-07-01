import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
import 'package:tekartik_firebase_functions_io/src/firebase_functions_io.dart'
    as io;

export 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
export 'package:tekartik_firebase_functions_io/src/firebase_functions_io.dart'
    show serve;

FirebaseFunctionsHttp get firebaseFunctionsIo => io.firebaseFunctionsIo;

/// Default functions service memory.
FirebaseFunctionsServiceHttp get firebaseFunctionsServiceIo =>
    io.firebaseFunctionsServiceIo;
