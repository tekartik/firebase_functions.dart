import 'package:dev_test/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [
    'firebase_functions',
    'firebase_functions_http',
    'firebase_functions_io',
    'firebase_functions_test'
  ]) {
    await packageRunCi(join('..', dir));
  }
}
