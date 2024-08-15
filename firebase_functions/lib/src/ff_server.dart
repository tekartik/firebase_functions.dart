/// Firebase functions server
abstract class FfServer {
  /// Client uri
  Uri get uri;

  /// Close the server
  Future<void> close();
}
