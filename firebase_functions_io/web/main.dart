// ignore_for_file: depend_on_referenced_packages

import 'package:http/http.dart';
import 'package:tekartik_http/http.dart';
import 'package:tekartik_test_menu_browser/test_menu_universal.dart';

Future main(List<String> arguments) async {
  await mainMenu(arguments, () {
    item('http echo', () async {
      // This test cors on the web
      var client = Client();
      var result = await httpClientRead(
          client, httpMethodPost, Uri.parse('http://localhost:4999/echo'),
          body: 'test body');
      write('result: $result');
    });
  });
}
