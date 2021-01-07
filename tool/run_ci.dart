//@dart=2.9
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:dev_test/package.dart';

Future<void> main() async {
  for (var dir in [
    'firebase_functions',
    'firebase_functions_http',
    'firebase_functions_io',
    'firebase_functions_node',
    'firebase_functions_test'
  ]) {
    await packageRunCi(dir);
  }
}
