import 'package:tekartik_firebase_functions/firebase_functions.dart';

import 'package:tekartik_firebase_functions_io/src/firebase_functions_io.dart'
    as io;

export 'package:tekartik_firebase_functions_io/src/firebase_functions_io.dart'
    show serve;

FirebaseFunctions get firebaseFunctionsIo => io.firebaseFunctionsIo;
