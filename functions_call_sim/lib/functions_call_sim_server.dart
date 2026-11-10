/// Server side of the callable functions through the Tekartik firebase
/// simulator: the [FirebaseFunctionsCallSimPlugin] to pass to
/// `firebaseSimServe` (it registers the functions of each app with its init
/// function and serves them over http too). Dart VM.
library;

export 'src/firebase_sim_server_ext.dart' show FirebaseSimServerFunctionsExt;
export 'src/functions_call_sim_plugin.dart'
    show
        FirebaseFunctionsCallSimPlugin,
        FirebaseFunctionsCallSimPluginOptions,
        FirebaseFunctionSimAppInitFunction;
