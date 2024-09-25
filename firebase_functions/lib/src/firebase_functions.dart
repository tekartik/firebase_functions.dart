// import 'package:tekartik_http/http_server.dart';
import 'dart:async';

import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_functions/ff_server.dart';
import 'package:tekartik_firebase_functions/src/express_http_request.dart';

import 'firebase_functions_firestore.dart';
import 'firebase_functions_https.dart';
import 'firebase_functions_scheduler.dart';
import 'params.dart';

export 'package:tekartik_firebase_firestore/firestore.dart'
    show DocumentSnapshot, Timestamp;

/// Firebase functions service.
abstract class FirebaseFunctionsService {
  FirebaseFunctions functions(FirebaseApp app);
}

mixin FirebaseFunctionsServiceDefaultMixin {
  FirebaseFunctions functions(FirebaseApp app) =>
      throw UnimplementedError('FirebaseFunctions.function(app)');
}

/// Global namespace for Firebase Cloud Functions functionality.
abstract class FirebaseFunctions {
  /// HTTPS functions.
  HttpsFunctions get https;

  /// Firestore functions.
  FirestoreFunctions get firestore;

  /// Pubsub functions.
  PubsubFunctions get pubsub;

  /// Scheduler functions.
  SchedulerFunctions get scheduler;

  void operator []=(String key, FirebaseFunction function);

  /// Configures the regions to which to deploy and run a function.
  ///
  /// For a list of valid values see https://firebase.google.com/docs/functions/locations
  /// V1 only
  @Deprecated('Use setGlobalOptions')
  FirebaseFunctions region(String region);

  /// Configures memory allocation and timeout for a function.
  @Deprecated('Use setGlobalOptions')
  FirebaseFunctions runWith(RuntimeOptions options);

  /// Params
  Params get params;

  /// Set global options
  set globalOptions(GlobalOptions options);

  /// Serve
  Future<FfServer> serve({int? port});

  /// Default Firebase functions instance.
  static FirebaseFunctions get instance =>
      (FirebaseApp.instance as FirebaseAppMixin)
          .getProduct<FirebaseFunctions>()!;
}

mixin FirebaseFunctionsDefaultMixin implements FirebaseFunctions {
  /// Scheduler functions.
  @override
  SchedulerFunctions get scheduler =>
      throw UnimplementedError('FirebaseFunction.scheduler');

  /// Firestore functions.
  @override
  FirestoreFunctions get firestore =>
      throw UnimplementedError('FirebaseFunction.firestore');

  @override
  set globalOptions(GlobalOptions options) {
    throw UnimplementedError('FirebaseFunction.globalOptions');
  }

  @override
  void operator []=(String key, FirebaseFunction function) {
    throw UnimplementedError('FirebaseFunction.[]=');
  }

  @override
  HttpsFunctions get https =>
      throw UnimplementedError('FirebaseFunction.https');

  @override
  Params get params => throw UnimplementedError('FirebaseFunction.params');

  @override
  PubsubFunctions get pubsub =>
      throw UnimplementedError('FirebaseFunction.pubsub');

  /// Deprecated use setGlobalOptions
  @override
  FirebaseFunctions region(String region) =>
      throw UnimplementedError('FirebaseFunction.region');

  /// Deprecated user setGlobalOptions
  @override
  FirebaseFunctions runWith(RuntimeOptions options) =>
      throw UnimplementedError('FirebaseFunction.runWith');

  /// Serve
  @override
  Future<FfServer> serve({int? port}) async {
    throw UnimplementedError('FirebaseFunction.serve');
  }
}

/// Https request handler
typedef RequestHandler = FutureOr<void> Function(ExpressHttpRequest request);

/// Call context
abstract class CallContext {
  /// Auth information
  CallContextAuth? get auth;
}

/// Call context
abstract class CallContextAuth {
  // TODO no nnbd here?
  /// Auth information
  DecodedIdToken? get token;

  /// User id
  String? get uid;
}

/// Mixin for base implementation
mixin CallContextMixin implements CallContext {
  @override
  CallContextAuth? get auth => throw UnimplementedError('auth');
}

/// Mixin for base implementation
mixin CallContextAuthMixin implements CallContextAuth {
  @override
  DecodedIdToken? get token => throw UnimplementedError('token');

  @override
  String? get uid => throw UnimplementedError('uid');
}

/// Call request
abstract class CallRequest {
  /// Context
  CallContext get context;

  /// Query
  String? get text;

  /// Incoming data that could be decoded from json
  Object? get data;
}

/// Call request
mixin CallRequestMixin implements CallRequest {
  @override
  CallContext get context => throw UnimplementedError('context');

  @override
  String? get text => data?.toString();

  @override
  Object? get data => null;
}

/// Extension to get the body as a map
extension CallRequestExt on CallRequest {
  /// Get the body as a map
  Map<String, Object?> get dataAsMap => requestBodyAsJsonObject(data)!;

  /// Get the body as a text
  String? get dataAsText => requestBodyAsText(data);
}

/// Call request handler.
///
/// The object returned is the response. Could be a map object
typedef CallHandler = FutureOr<Object?> Function(CallRequest request);

abstract class FirebaseFunction {}

/// Pubsub function
abstract class PubsubFunction implements FirebaseFunction {}

//
// Pubsub
//

/// Schedule context.
abstract class ScheduleContext {}

/// Schedule event handler.
typedef ScheduleEventHandler = FutureOr<void> Function(ScheduleContext context);

/// Schedule builder.
abstract class ScheduleBuilder {
  /// Event handler that fires every time a schedule occurs.
  PubsubFunction onRun(ScheduleEventHandler handler);

  /// Set scheduler in a specific timezone
  ScheduleBuilder timeZone(String timeZone);
}

/// Pubsub functions.
abstract class PubsubFunctions {
  @Deprecated('Use scheduler from firebase functions')
  ScheduleBuilder schedule(String expression);
}

/// RunWith options
///
/// Tested on node, it is necessary to specify both parameters
class RuntimeOptions {
  /// Timeout for the function in seconds.
  final int? timeoutSeconds;

  /// Amount of memory to allocate to the function.
  ///
  /// Valid values are: '128MB', '256MB', '512MB', '1GB', and '2GB'.
  final String? memory;

  RuntimeOptions({this.timeoutSeconds, this.memory});
}

// https://cloud.google.com/compute/docs/regions-zones
/// Belgium location, V2 ok
const regionBelgium = 'europe-west1';

/// Frankfurt location
const regionFrankfurt = 'europe-west3';

/// Us central 1, default region for firebase serve.
const regionUsCentral1 = 'us-central1';

/// Memory
const runtimeOptionsMemory128MB = '128MB';
const runtimeOptionsMemory256MB = '256MB';
const runtimeOptionsMemory512MB = '512MB';
const runtimeOptionsMemory1GB = '1GB';
const runtimeOptionsMemory2GB = '2GB';

/// Global firebase function options
class GlobalOptions {
  /// Either region or regions
  final String? region;
  final List<String>? regions;

  /// Amount of memory to allocate to a function.
  /// "128MiB" | "256MiB" | "512MiB" | "1GiB" | "2GiB" | "4GiB" | "8GiB" | "16GiB" | "32GiB";
  /// external Object? get region;

  final String? memory;

  /// Number of requests a function can serve at once.

  final int? concurrency;

  /// Timeout for the function in sections, possible values are 0 to 540. HTTPS functions can specify a higher timeout.
  final int? timeoutSeconds;

  GlobalOptions(
      {this.timeoutSeconds,
      this.region,
      this.regions,
      this.memory,
      this.concurrency});
}
