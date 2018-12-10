import 'package:grinder/grinder.dart';
import "package:tekartik_build_utils/common_import.dart";

main(List<String> args) => grind(args);

@Task()
test() => TestRunner().testAsync();

@Depends(test)
build() {
  Pub.build();
}

String buildFolder =
    join('.dart_tool', 'tekartik_firebase_function_node', 'build');

String projectIdDev = 'tekartik-free-dev';
String projectId = projectIdDev;

@DefaultTask()
firebase_serve() async {
  await runCmd(PubCmd([
    'run',
    'build_runner',
    'build',
    '--output',
    'node_functions:$buildFolder'
  ]));
  await copy(File(join(buildFolder, 'index.dart.js')), Directory('functions'));
  await runCmd(FirebaseCmd(firebaseArgs(serve: true, onlyFunctions: true)));
}

@Task()
clean() => defaultClean();

@Task()
build_test() async {
  //await Pub.build(directories: [binDir.path]);
  await runCmd(PubCmd(
      pubRunArgs(['build_runner', 'build', '--output', 'test:build/test'])));
  //await copy_build();
}

@Task()
watch() async {
  await runCmd(PubCmd(
      pubRunArgs(['build_runner', 'watch', '--output', 'test:build/test'])));
}
