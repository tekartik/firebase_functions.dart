import 'package:tekartik_firebase_functions_io/src/firebase_functions_io.dart'
    as io;

import 'firebase_functions_http.dart';

export 'package:tekartik_firebase_functions_io/src/firebase_functions_io.dart'
    show serve;

export 'firebase_functions_http.dart';

FirebaseFunctionsHttp get firebaseFunctionsIo => io.firebaseFunctionsIo;
