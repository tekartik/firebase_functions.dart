import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

import 'functions_call_sim_server_service.dart';

/// Initialization callback for the Firebase Functions Call Sim Plugin
typedef FirebaseFunctionSimAppInitCallback =
    void Function({required FirebaseApp firebaseApp});

/// Options for the Firebase Functions Call Sim Plugin
class FirebaseFunctionsCallSimPluginOptions {
  /// Init functions map
  final Map<String, FirebaseFunctionSimAppInitCallback> initFunctions;

  /// Constructor
  FirebaseFunctionsCallSimPluginOptions({required this.initFunctions});
}

/// Service plugin
abstract class FirebaseFunctionsCallSimPlugin implements FirebaseSimPlugin {
  /// Options for the plugin
  FirebaseFunctionsCallSimPluginOptions get options;

  /// functions service implementation
  FirebaseFunctionsServiceHttp get firebaseFunctionsService;

  /// Constructor
  factory FirebaseFunctionsCallSimPlugin.compat({
    required FirebaseFunctionsHttp firebaseFunctions,
  }) => _FirebaseFunctionsCallSimPlugin.compat(
    firebaseFunctions: firebaseFunctions,
  );

  /// Constructor
  factory FirebaseFunctionsCallSimPlugin({
    required FirebaseFunctionsServiceHttp firebaseFunctionsService,
    required FirebaseFunctionsCallSimPluginOptions options,
  }) => _FirebaseFunctionsCallSimPlugin(
    firebaseFunctionsService: firebaseFunctionsService,
    options: options,
  );

  @override
  FirebaseSimServerService get simService;
}

/// Service plugin
class _FirebaseFunctionsCallSimPlugin
    implements FirebaseFunctionsCallSimPlugin {
  @override
  late final FirebaseFunctionsCallSimPluginOptions options;
  @override
  late final FirebaseFunctionsServiceHttp firebaseFunctionsService;

  /// functions call implementation (compat)
  late final FirebaseFunctionsHttp? firebaseFunctions;

  /// Sim server service
  final firebaseFunctionsCallSimServerService =
      FirebaseFunctionsCallSimServerService();

  /// Constructor
  _FirebaseFunctionsCallSimPlugin.compat({
    required FirebaseFunctionsHttp firebaseFunctions,
  }) {
    // ignore: prefer_initializing_formals
    this.firebaseFunctions = firebaseFunctions;
    firebaseFunctionsCallSimServerService.firebaseFunctionsCallSimPlugin = this;
    firebaseFunctionsService =
        firebaseFunctions.service as FirebaseFunctionsServiceHttp;
    options = FirebaseFunctionsCallSimPluginOptions(initFunctions: {});
  }

  @override
  FirebaseSimServerService get simService =>
      firebaseFunctionsCallSimServerService;

  _FirebaseFunctionsCallSimPlugin({
    required this.firebaseFunctionsService,
    required this.options,
  }) {
    firebaseFunctionsCallSimServerService.firebaseFunctionsCallSimPlugin = this;
  }
}

/// FirebaseFunctionsCallSimPlugin private extension
extension FirebaseFunctionsCallSimPluginPrvExt
    on FirebaseFunctionsCallSimPlugin {
  _FirebaseFunctionsCallSimPlugin get _self =>
      this as _FirebaseFunctionsCallSimPlugin;
  @Deprecated('Do not use this, use firebaseFunctionsService instead')
  /// The functions call implementation
  FirebaseFunctionsHttp get firebaseFunctions => _self.firebaseFunctions!;
}
