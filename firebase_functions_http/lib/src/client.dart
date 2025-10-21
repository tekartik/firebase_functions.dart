import 'constant.dart';

/// Get the default Firebase Simulator port.
int getFirebaseFunctionsHttpPort([int? port]) {
  port ??= firebaseFunctionsHttpDefaultPort;
  return port;
}

/// Get the default Firebase Simulator URL.
Uri getFirebaseFunctionsHttpLocalhostUri({int? port}) {
  var foundPort = getFirebaseFunctionsHttpPort(port);
  return Uri.parse('$firebaseFunctionHttpLocalhostBaseUrl:$foundPort');
}
