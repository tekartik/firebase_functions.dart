import 'package:grinder/grinder.dart';
import 'package:process_run/process_run.dart';
import 'package:tekartik_build_utils/bash/bash.dart';

String extraOptions = '';

main(List<String> args) {
  // Handle extra args after --
  // to specify test names
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--') {
      extraOptions = argumentsToString(args.sublist(i + 1));
      // remove the extra args
      args = args.sublist(0, i);
      break;
    }
  }
  grind(args);
}

@Task()
test() async {}

@Task()
fmt() async {
  await bash('''
set -xe
dartfmt . -w
''', verbose: true);
}

@DefaultTask()
help() {
  print('Quick help:');
  print('  fmt: format');
}
