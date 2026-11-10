/// `firebaseFunctionsCallServiceMemory`: calls the in process memory server
/// of `tekartik_firebase_functions_http` (no socket).
library;

export 'functions_call_http.dart';
export 'src/functions_call_memory.dart' show firebaseFunctionsCallServiceMemory;
