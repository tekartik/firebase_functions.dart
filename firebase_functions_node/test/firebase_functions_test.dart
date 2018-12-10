@TestOn('vm')
library tekartik_firebase_functions_node.test.firebase_functions_test;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fs_shim/utils/io/copy.dart';
import 'package:path/path.dart';
import 'package:tekartik_build_utils/cmd_run.dart';
import 'package:tekartik_build_utils/firebase/firebase.dart';
import 'package:test/test.dart';
import 'package:tekartik_http_io/http_client_io.dart';

import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart'
    as common;

String buildFolder =
    join('.dart_tool', 'tekartik_firebase_function_node', 'test');

Future<Process> firebaseBuildCopyAndServe() async {
  await runCmd(PubCmd([
    'run',
    'build_runner',
    'build',
    '--output',
    'node_functions:$buildFolder'
  ]));
  await copyFile(File(join(buildFolder, 'index.dart.js')),
      File(join('functions', 'index.dart.js')));
  var cmd = FirebaseCmd(firebaseArgs(serve: true, onlyFunctions: true));
  var completer = Completer<Process>();
  var process = await Process.start(cmd.executable, cmd.arguments);
  process.stdout
      .transform(Utf8Decoder())
      .transform(LineSplitter())
      .listen((line) {
    // wait for the lines
    // +  functions: echo: http://localhost:5000/tekartik-free-dev/us-central1/echo
    // +  functions: echoFragment: http://localhost:5000/tekartik-free-dev/us-central1/echoFragment
    // +  functions: echoQuery: http://localhost:5000/tekartik-free-dev/us-central1/echoQuery
    print("$line");
    if (line
        .contains('http://localhost:5000/tekartik-free-dev/us-central1/echo')) {
      if (!completer.isCompleted) {
        completer.complete(process);
      }
    }
  });
  return completer.future;
}

Future main() async {
  var httpClientFactory = httpClientFactoryIo;

  var process = await firebaseBuildCopyAndServe();
  group('firebase_functions_io', () {
    group('echo', () {
      setUpAll(() async {});

      common.main(
          httpClientFactory: httpClientFactory,
          baseUrl: 'http://localhost:5000/tekartik-free-dev/us-central1');
      tearDownAll(() async {
        // await server.close();
        await process.kill();
      });
    });
  });
}
