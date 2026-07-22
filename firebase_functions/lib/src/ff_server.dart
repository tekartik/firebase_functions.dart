/// A local HTTP server used to serve Firebase functions, as returned by
/// [FirebaseFunctions.serve].
///
/// Useful for local development and testing without deploying to Firebase.
abstract class FfServer {
  /// The base [Uri] the server is listening on (host and port), used to
  /// build request URLs against the served functions.
  Uri get uri;

  /// Stops the server from listening for new requests and releases the
  /// underlying resources.
  ///
  /// The returned [Future] completes once the server has fully shut down.
  Future<void> close();
}
