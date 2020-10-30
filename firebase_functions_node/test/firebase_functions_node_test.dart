@TestOn('vm')
library tekartik_firebase_functions_node.test.firebase_functions_test;

import 'dart:async';
import 'dart:io';

import 'package:fs_shim/utils/io/copy.dart';
import 'package:path/path.dart';
import 'package:process_run/which.dart';
import 'package:tekartik_build_utils/cmd_run.dart';
import 'package:tekartik_build_utils/travis/travis.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:test/test.dart';

String buildFolder = join('build', 'tekartik_firebase_function_node');

Future<Process> firebaseBuildCopyAndServe({TestContext context}) async {
  await runCmd(
      PubCmd(['run', 'build_runner', 'build', '--output', 'bin:$buildFolder']));
  await copyFile(File(join(buildFolder, 'main.dart.js')),
      File(join('deploy', 'functions', 'index.js')));
  //var cmd = FirebaseCmd(
  //    firebaseArgs(serve: true, onlyFunctions: true, projectId: 'dev'));
  //var completer = Completer<Process>();
  //print('firebase serve 1');
  //await Shell().cd('deploy').run('firebase serve');
  print('firebase serve');
  // await Shell().cd('deploy').run('firebase serve');
  /*
  var process = await Process.start(await which('firebase'), ['serve'],
      workingDirectory: 'deploy');
  process.stdout
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .listen((line) {
    // wait for the lines
    // +  functions: echo: http://localhost:5000/tekartik-free-dev/us-central1/echo
    // +  functions: echoFragment: http://localhost:5000/tekartik-free-dev/us-central1/echoFragment
    // +  functions: echoQuery: http://localhost:5000/tekartik-free-dev/us-central1/echoQuery
    print('serve $line');
    if (line.contains(url.join(context.baseUrl, 'echo'))) {
      if (!completer.isCompleted) {
        completer.complete(process);
      }
    }
  });
  process.stderr
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .listen((line) {
    print('error: $line');
  });
  unawaited(process.exitCode.then((exitCode) async {
    if (!completer.isCompleted) {
      //await stderr.addStream(process.stderr);
      print('exitCode: ${exitCode}');
      completer.completeError('exitCode: $exitCode');
    }
  }));

   */
  //return completer.future;
  return null;
}

Future main() async {
  //var httpClientFactory = httpClientFactoryIo;

  var context = TestContext();

  context.baseUrl = 'http://localhost:5000/tekartik-free-dev/us-central1';

  final firebaseInstalled = whichSync('firebase') != null;
  group('firebase_functions_io', () {
    group('echo', () {
      Process process;
      setUpAll(() async {
        process = await firebaseBuildCopyAndServe(context: context);
      });

      /*TODO temp excluded
      common.main(
          testContext: FirebaseFunctionsTestContext(
              httpClientFactory: httpClientFactory),
          httpClientFactory: httpClientFactory,
          baseUrl: context.baseUrl);

       */
      tearDownAll(() async {
        // await server.close();
        process?.kill();
      });
    }, skip: !firebaseInstalled || runningInTravis);
  });
}