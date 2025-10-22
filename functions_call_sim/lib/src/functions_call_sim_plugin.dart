import 'package:tekartik_firebase_functions_http/firebase_functions_http.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server_mixin.dart';

import 'functions_call_sim_server_service.dart';

/// Initialization callback for the Firebase Functions Call Sim Plugin
typedef FirebaseFunctionSimAppInitFunction =
    void Function({required FirebaseApp firebaseApp});

/// Options for the Firebase Functions Call Sim Plugin
class FirebaseFunctionsCallSimPluginOptions {
  /// HTTP port for the http functions
  final int? httpPort;

  /// Init functions map
  final Map<String, FirebaseFunctionSimAppInitFunction>? initFunctions;

  /// Global init function
  final FirebaseFunctionSimAppInitFunction? initFunction;

  /// Constructor
  FirebaseFunctionsCallSimPluginOptions({
    this.initFunctions,
    this.initFunction,
    this.httpPort,
  });
}

/// Service plugin
abstract class FirebaseFunctionsCallSimPlugin implements FirebaseSimPlugin {
  /// Options for the plugin
  FirebaseFunctionsCallSimPluginOptions get options;

  /// functions service implementation
  FirebaseFunctionsServiceHttp get firebaseFunctionsService;

  /// Constructor
  @Deprecated('Use FirebaseFunctionsCallSimPlugin constructor instead')
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

/// Current Firebase Functions HTTP server URI
Uri get firebaseSimHttpServerUri =>
    _FirebaseFunctionsCallSimPlugin._httpServer!.clientUri;

/// Service plugin
class _FirebaseFunctionsCallSimPlugin
    with FirebaseSimPluginDefaultMixin
    implements FirebaseFunctionsCallSimPlugin {
  static HttpServer? _httpServer;
  @override
  late final FirebaseFunctionsCallSimPluginOptions options;
  @override
  late final FirebaseFunctionsServiceHttp firebaseFunctionsService;

  /// functions call implementation (compat)
  late FirebaseFunctionsHttp? firebaseFunctions;
  @override
  Future<void> initForApp(FirebaseApp app) async {
    var firebaseFunctionsService = this.firebaseFunctionsService;
    //late FirebaseFunctionsHttp firebaseFunctions;
    var options = this.options;

    var initFunction =
        options.initFunctions?[app.options.projectId] ?? options.initFunction;
    if (initFunction != null) {
      firebaseFunctions = firebaseFunctionsService.functions(app);
      initFunction(firebaseApp: app);
      if (_httpServer == null) {
        var httpServer = await firebaseFunctions!.serveHttp(
          port: options.httpPort,
        );
        // print('http: ${httpServerGetUri(httpServer)}');
        _httpServer = httpServer;
      }
    }
  }

  /// Sim server service
  final firebaseFunctionsCallSimServerService =
      FirebaseFunctionsCallSimServerService();

  /// Constructor
  @Deprecated('Use FirebaseFunctionsCallSimPlugin constructor instead')
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
