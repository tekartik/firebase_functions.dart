import 'package:cv/cv.dart';

/// Init cv builders
void initFunctionsCallSimBuilders() {
  cvAddConstructors([CallSimRequest.new, CallSimResult.new]);
}

/// Call
const methodFunctionsCall = 'call';

/// Call
class CallSimRequest extends CvModelBase {
  /// Logged in user id if any
  final userId = CvField<String>('userId');

  /// callable name
  final name = CvField<String>('name');

  /// Body text
  final body = CvField<String>('body');

  @override
  CvFields get fields => [name, userId, body];
}

/// Call result message
class CallSimResult extends CvModelBase {
  /// Success data
  final success = CvField<String>('success');

  /// Error
  final error = CvField<Map>('error');

  @override
  CvFields get fields => [success, error];
}
