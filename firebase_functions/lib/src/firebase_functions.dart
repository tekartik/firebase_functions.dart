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

/// Firebase functions service, the entry point used to obtain the
/// [FirebaseFunctions] product bound to a given [FirebaseApp].
abstract class FirebaseFunctionsService {
  /// Returns the [FirebaseFunctions] instance associated with [app].
  ///
  /// Implementations typically cache and return the same instance for a
  /// given [app] across calls.
  FirebaseFunctions functions(FirebaseApp app);
}

/// Default mixin for [FirebaseFunctionsService] implementations that have
/// not (yet) implemented [functions].
mixin FirebaseFunctionsServiceDefaultMixin {
  /// {@template tekartik_firebase_functions.defaultMixinUnimplemented}
  /// Default implementation, throws an [UnimplementedError].
  ///
  /// Concrete implementations must override this member.
  /// {@endtemplate}
  FirebaseFunctions functions(FirebaseApp app) =>
      throw UnimplementedError('FirebaseFunctions.function(app)');
}

/// Global namespace for Firebase Cloud Functions functionality.
abstract class FirebaseFunctions
    implements FirebaseAppProduct<FirebaseFunctions> {
  /// Firebase app.
  @override
  FirebaseApp get app;

  /// Firebase functions service.
  FirebaseFunctionsService get service;

  /// HTTPS functions.
  HttpsFunctions get https;

  /// Firestore functions.
  FirestoreFunctions get firestore;

  /// Pubsub functions.
  PubsubFunctions get pubsub;

  /// Scheduler functions.
  SchedulerFunctions get scheduler;

  /// {@template tekartik_firebase_functions.registerFunction}
  /// Registers [function] so it is deployed and served under the name
  /// [key].
  ///
  /// [key] is the function name as it will appear in the Firebase Functions
  /// dashboard and in its invocation URL/trigger name. Registering another
  /// function under an existing [key] replaces the previous registration.
  /// {@endtemplate}
  void operator []=(String key, FirebaseFunction function);

  /// {@macro tekartik_firebase_functions.registerFunction}
  ///
  /// Equivalent to `this[name] = function`.
  void registerFunction(String name, FirebaseFunction function);

  /// Configures the regions to which to deploy and run a function.
  ///
  /// [region] is a Firebase/Google Cloud region identifier (see
  /// [regionBelgium], [regionFrankfurt] and [regionUsCentral1] for common
  /// values). For a list of valid values see
  /// https://firebase.google.com/docs/functions/locations
  ///
  /// Returns this [FirebaseFunctions] instance for chaining. V1 only.
  @Deprecated('Use setGlobalOptions')
  FirebaseFunctions region(String region);

  /// Configures memory allocation and timeout for a function.
  ///
  /// [options] describes the memory and timeout to apply. Returns this
  /// [FirebaseFunctions] instance for chaining.
  @Deprecated('Use setGlobalOptions')
  FirebaseFunctions runWith(RuntimeOptions options);

  /// The functions parameters, such as the current Firebase project id.
  Params get params;

  /// Sets the [GlobalOptions] (region, memory, timeout, concurrency, max
  /// instances, ...) applied by default to functions registered afterwards
  /// that do not specify their own options.
  set globalOptions(GlobalOptions options);

  /// Starts a local HTTP server exposing the registered functions, for
  /// local development and testing.
  ///
  /// [port] is the TCP port to listen on. If omitted (`null`), an
  /// implementation-defined default or an ephemeral port is used.
  ///
  /// The returned [Future] completes with the [FfServer] once the server is
  /// ready to accept requests.
  Future<FfServer> serve({int? port});

  /// The default [FirebaseFunctions] instance, bound to
  /// [FirebaseApp.instance].
  ///
  /// Throws if [FirebaseApp.instance] has not been initialized or does not
  /// have a registered [FirebaseFunctions] product.
  static FirebaseFunctions get instance =>
      (FirebaseApp.instance as FirebaseAppMixin)
          .getProduct<FirebaseFunctions>()!;
}

/// Default mixin for [FirebaseFunctions] implementations, where every
/// member throws an [UnimplementedError] unless overridden by the concrete
/// implementation.
mixin FirebaseFunctionsDefaultMixin implements FirebaseFunctions {
  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  FirebaseApp get app => throw UnimplementedError('FirebaseFunctions.app');

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  FirebaseFunctionsService get service =>
      throw UnimplementedError('FirebaseFunctions.service');

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  SchedulerFunctions get scheduler =>
      throw UnimplementedError('FirebaseFunctions.scheduler');

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  FirestoreFunctions get firestore =>
      throw UnimplementedError('FirebaseFunctions.firestore');

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  set globalOptions(GlobalOptions options) {
    throw UnimplementedError('FirebaseFunctions.globalOptions');
  }

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  void operator []=(String key, FirebaseFunction function) {
    throw UnimplementedError('FirebaseFunctions.[]=');
  }

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  void registerFunction(String name, FirebaseFunction function) {
    throw UnimplementedError('FirebaseFunctions.registerFunction ($this)');
  }

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  HttpsFunctions get https =>
      throw UnimplementedError('FirebaseFunctions.https');

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  Params get params => throw UnimplementedError('FirebaseFunctions.params');

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  PubsubFunctions get pubsub =>
      throw UnimplementedError('FirebaseFunctions.pubsub');

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  ///
  /// Deprecated, use [FirebaseFunctions.globalOptions] instead.
  @override
  FirebaseFunctions region(String region) =>
      throw UnimplementedError('FirebaseFunction.region');

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  ///
  /// Deprecated, use [FirebaseFunctions.globalOptions] instead.
  @override
  FirebaseFunctions runWith(RuntimeOptions options) =>
      throw UnimplementedError('FirebaseFunction.runWith');

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  Future<FfServer> serve({int? port}) async {
    throw UnimplementedError('FirebaseFunction.serve');
  }
}

/// Signature of a raw HTTPS request handler, as registered through
/// [HttpsFunctions.onRequest].
///
/// [request] gives access to the incoming [ExpressHttpRequest] (body, uri,
/// headers) and its [ExpressHttpRequest.response], which the handler is
/// responsible for writing to and closing. The returned [FutureOr] should
/// complete once the response has been fully written.
typedef RequestHandler = FutureOr<void> Function(ExpressHttpRequest request);

/// The context of an incoming callable function call, currently exposing
/// authentication information.
abstract class CallContext {
  /// Authentication information for the caller, or `null` if the call was
  /// not authenticated.
  CallContextAuth? get auth;
}

/// Authentication information for a call made through a callable function.
abstract class CallContextAuth {
  // TODO no nnbd here?
  /// The decoded Firebase Auth ID token of the caller, or `null` if not
  /// available.
  DecodedIdToken? get token;

  /// The uid of the authenticated user, or `null` if not authenticated.
  String? get uid;
}

/// Default mixin for [CallContext] implementations.
mixin CallContextMixin implements CallContext {
  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  CallContextAuth? get auth => throw UnimplementedError('auth');
}

/// Default mixin for [CallContextAuth] implementations.
mixin CallContextAuthMixin implements CallContextAuth {
  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  DecodedIdToken? get token => throw UnimplementedError('token');

  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  String? get uid => throw UnimplementedError('uid');
}

/// An incoming call made to a callable function, as passed to a
/// [CallHandler].
abstract class CallRequest {
  /// The [CallContext] (authentication, ...) of this call.
  CallContext get context;

  /// The raw incoming [data] converted to its string representation, or
  /// `null` if [data] is `null`.
  String? get text;

  /// The incoming payload, typically a JSON-decodable `Map`, `List`,
  /// `String` or `null` value.
  Object? get data;
}

/// Default mixin for [CallRequest] implementations.
mixin CallRequestMixin implements CallRequest {
  /// {@macro tekartik_firebase_functions.defaultMixinUnimplemented}
  @override
  CallContext get context => throw UnimplementedError('context');

  /// Default implementation, returns the string representation of [data],
  /// or `null` if [data] is `null`.
  @override
  String? get text => data?.toString();

  /// Default implementation, always returns `null`. Concrete
  /// implementations must override this member.
  @override
  Object? get data => null;
}

/// Convenience accessors to interpret [CallRequest.data] as JSON.
extension CallRequestExt on CallRequest {
  /// The [CallRequest.data] as a `Map<String, Object?>`.
  ///
  /// Throws a [TypeError] if [CallRequest.data] is `null` or cannot be
  /// interpreted as a JSON object (see [requestBodyAsJsonObject]).
  Map<String, Object?> get dataAsMap => requestBodyAsJsonObject(data)!;

  /// The [CallRequest.data] converted to its text representation (see
  /// [requestBodyAsText]).
  String get dataAsText => requestBodyAsText(data);
}

/// Call request handler, registered through [HttpsFunctions.onCall].
///
/// The object returned is sent back as the response. It could be a map
/// object or any other JSON-encodable value.
typedef CallHandler = FutureOr<Object?> Function(CallRequest request);

/// Base type shared by every kind of registered Firebase function (HTTPS,
/// callable, Firestore, pubsub, scheduled, ...).
abstract class FirebaseFunction {}

/// A function triggered by a pubsub schedule, as created by
/// [ScheduleBuilder.onRun].
abstract class PubsubFunction implements FirebaseFunction {}

//
// Pubsub
//

/// The context in which a scheduled pubsub event occurred.
///
/// Currently carries no extra information beyond identifying that a
/// schedule fired.
abstract class ScheduleContext {}

/// Signature of a handler invoked every time a scheduled pubsub event
/// fires, receiving the [ScheduleContext] of the occurrence.
typedef ScheduleEventHandler = FutureOr<void> Function(ScheduleContext context);

/// Builder used to configure and register a function that runs on a pubsub
/// schedule.
abstract class ScheduleBuilder {
  /// Registers [handler] to be invoked every time the schedule occurs, and
  /// returns the resulting [PubsubFunction].
  PubsubFunction onRun(ScheduleEventHandler handler);

  /// Sets the timezone the schedule is evaluated in.
  ///
  /// [timeZone] is a timezone identifier (e.g. `'America/Los_Angeles'`).
  /// Returns this [ScheduleBuilder] for chaining.
  ScheduleBuilder timeZone(String timeZone);
}

/// Pubsub-based scheduling functions.
abstract class PubsubFunctions {
  /// Starts building a scheduled function using [expression] (a Unix
  /// Crontab or AppEngine schedule syntax expression).
  ///
  /// Deprecated, use [SchedulerFunctions.onSchedule] instead.
  @Deprecated('Use scheduler from firebase functions')
  ScheduleBuilder schedule(String expression);
}

/// Options passed to [FirebaseFunctions.globalOptions] to configure memory and
/// timeout for a function.
///
/// Deprecated, use [GlobalOptions] with [FirebaseFunctions.globalOptions]
/// instead. Tested on node, it is necessary to specify both parameters.
class RuntimeOptions {
  /// Timeout for the function in seconds.
  final int? timeoutSeconds;

  /// Amount of memory to allocate to the function.
  ///
  /// Valid values are: '128MB', '256MB', '512MB', '1GB', and '2GB' (see
  /// [runtimeOptionsMemory128MB] and friends).
  final String? memory;

  /// Creates the runtime options to pass to [FirebaseFunctions.globalOptions].
  ///
  /// [timeoutSeconds] and [memory] are both nullable; omitting either
  /// leaves the corresponding setting at its platform default. Both are
  /// required in practice when deploying to Node.
  RuntimeOptions({this.timeoutSeconds, this.memory});
}

// https://cloud.google.com/compute/docs/regions-zones
/// Belgium location, V2 ok.
///
/// Preferred region for cloud functions.
const regionBelgium = 'europe-west1';

/// Europe West 9 location Paris.
///
/// Preferred region for Firestore/functions.
const regionParisEuropeWest9 = 'europe-west9';

/// Frankfurt location.
///
/// Preferred region for Firestore.
const regionFrankfurt = 'europe-west3';

/// Us central 1, the default region used by `firebase serve`/emulators.
const regionUsCentral1 = 'us-central1';

/// 128 MB of memory, for use with [RuntimeOptions.memory].
const runtimeOptionsMemory128MB = '128MB';

/// 256 MB of memory, for use with [RuntimeOptions.memory].
const runtimeOptionsMemory256MB = '256MB';

/// 512 MB of memory, for use with [RuntimeOptions.memory].
const runtimeOptionsMemory512MB = '512MB';

/// 1 GB of memory, for use with [RuntimeOptions.memory].
const runtimeOptionsMemory1GB = '1GB';

/// 2 GB of memory, for use with [RuntimeOptions.memory].
const runtimeOptionsMemory2GB = '2GB';

/// Global options applied when deploying a Firebase function, set through
/// [FirebaseFunctions.globalOptions] and extended by [HttpsOptions] and
/// [ScheduleOptions] for function-type-specific options.
class GlobalOptions {
  /// The single region to deploy to, mutually exclusive with [regions].
  ///
  /// See [regionBelgium], [regionFrankfurt] and [regionUsCentral1] for
  /// common values.
  final String? region;

  /// The list of regions to deploy to, mutually exclusive with [region].
  ///
  /// `null` or omitted deploys to the platform default region only.
  final List<String>? regions;

  /// Amount of memory to allocate to a function.
  ///
  /// Valid values are: "128MiB", "256MiB", "512MiB", "1GiB", "2GiB",
  /// "4GiB", "8GiB", "16GiB" and "32GiB". `null` leaves the platform
  /// default in effect.
  final String? memory;

  /// Number of requests a function instance can serve at once.
  ///
  /// `null` leaves the platform default concurrency in effect.
  final int? concurrency;

  /// Timeout for the function in seconds, possible values are 0 to 540.
  /// HTTPS functions can specify a higher timeout. `null` leaves the
  /// platform default timeout in effect.
  final int? timeoutSeconds;

  /// Max number of instances the function may scale up to. `null` leaves
  /// the platform default limit in effect.
  final int? maxInstances;

  /// Creates a set of global options. Every parameter is optional; a `null`
  /// or omitted value leaves the corresponding setting at its platform
  /// default.
  GlobalOptions({
    this.timeoutSeconds,
    this.region,
    this.regions,
    this.memory,
    this.concurrency,
    this.maxInstances,
  });
}
