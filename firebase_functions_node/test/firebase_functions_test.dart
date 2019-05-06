@TestOn('vm')
library tekartik_firebase_functions_node.test.firebase_functions_test;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fs_shim/utils/io/copy.dart';
import 'package:path/path.dart';
import 'package:pedantic/pedantic.dart';
import 'package:process_run/which.dart';
import 'package:tekartik_build_utils/cmd_run.dart';
import 'package:tekartik_build_utils/firebase/firebase.dart';
import 'package:tekartik_build_utils/travis/travis.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_setup.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart'
    as common;
import 'package:tekartik_http_io/http_client_io.dart';
import 'package:test/test.dart';

String buildFolder =
    join('.dart_tool', 'tekartik_firebase_function_node', 'test');

Future<Process> firebaseBuildCopyAndServe({TestContext context}) async {
  await runCmd(PubCmd([
    'run',
    'build_runner',
    'build',
    '--output',
    'node_functions:$buildFolder'
  ]));
  await copyFile(File(join(buildFolder, 'index.dart.js')),
      File(join('functions', 'index.dart.js')));
  var cmd = FirebaseCmd(
      firebaseArgs(serve: true, onlyFunctions: true, projectId: 'dev'));
  var completer = Completer<Process>();
  var process = await Process.start(cmd.executable, cmd.arguments);
  process.stdout
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .listen((line) {
    // wait for the lines
    // +  functions: echo: http://localhost:5000/tekartik-free-dev/us-central1/echo
    // +  functions: echoFragment: http://localhost:5000/tekartik-free-dev/us-central1/echoFragment
    // +  functions: echoQuery: http://localhost:5000/tekartik-free-dev/us-central1/echoQuery
    print("serve $line");
    if (line.contains(url.join(context.baseUrl, 'echo'))) {
      if (!completer.isCompleted) {
        completer.complete(process);
      }
    }
  });
  unawaited(process.exitCode.then((exitCode) async {
    if (!completer.isCompleted) {
      await stderr.addStream(process.stderr);
      print('exitCode: ${exitCode}');
      completer.completeError('exitCode: $exitCode');
    }
  }));
  return completer.future;
}

Future main() async {
  var httpClientFactory = httpClientFactoryIo;

  var context = TestContext();

  context.baseUrl = 'http://localhost:5000/tekartik-free-dev/us-central1';

  bool firebaseInstalled = whichSync('firebase') != null;
  group('firebase_functions_io', () {
    group('echo', () {
      Process process;
      setUpAll(() async {
        process = await firebaseBuildCopyAndServe(context: context);
      });

      common.main(
          httpClientFactory: httpClientFactory, baseUrl: context.baseUrl);
      tearDownAll(() async {
        // await server.close();
        process?.kill();
      });
    }, skip: !firebaseInstalled || runningInTravis);
  });
}
