library;

export 'package:tekartik_firebase/firebase.dart';
export 'package:tekartik_firebase_functions/firebase_functions.dart'
    show regionBelgium, regionUsCentral1, regionFrankfurt;

export 'src/functions_call.dart'
    show
        FirebaseFunctionsCall,
        FirebaseFunctionsCallable,
        FirebaseFunctionsCallDefaultMixin,
        FirebaseFunctionsCallableOptions,
        FirebaseFunctionsCallableResult,
        FirebaseFunctionsCallableResultExt,
        FirebaseFunctionsCallableResultDefaultMixin;
export 'src/functions_call_service.dart'
    show
        FirebaseFunctionsCallOptions,
        FirebaseFunctionsCallService,
        FirebaseFunctionsCallServiceDefaultMixin;
