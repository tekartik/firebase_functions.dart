import 'package:grinder/grinder.dart';
import "package:tekartik_build_utils/common_import.dart";

main(List<String> args) => grind(args);

@Task()
test() => new TestRunner().testAsync();

@DefaultTask()
@Depends(test)
build() {
  Pub.build();
}

@Task()
clean() => defaultClean();

@Task()
build_test() async {
  //await Pub.build(directories: [binDir.path]);
  await runCmd(pubCmd(
      pubRunArgs(['build_runner', 'build', '--output', 'test:build/test'])));
  //await copy_build();
}

@Task()
watch() async {
  await runCmd(pubCmd(
      pubRunArgs(['build_runner', 'watch', '--output', 'test:build/test'])));
}
