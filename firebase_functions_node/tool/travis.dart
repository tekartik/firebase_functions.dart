import 'package:process_run/shell.dart';

import 'build.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''
dartanalyzer --fatal-warnings --fatal-infos lib test tool node_functions
pub run test -p vm
''');

  await build();
}
