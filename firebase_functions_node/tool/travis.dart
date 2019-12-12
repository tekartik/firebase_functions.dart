import 'package:process_run/shell.dart';

import 'build.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''
  # Analyze code
  dartanalyzer --fatal-warnings --fatal-infos lib test tool node_functions
  dartfmt -n --set-exit-if-changed lib test tool node_functions

  pub run test -p vm
''');

  await build();
}
