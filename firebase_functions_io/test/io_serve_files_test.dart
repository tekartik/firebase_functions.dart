@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_functions_io/src/firebase_functions_io.dart'
    show publicDirFilePath;
import 'package:tekartik_http_io/http_client_io.dart';
import 'package:test/test.dart';

void main() {
  group('serve files', () {
    late io.Directory dir;
    late io.File secret;
    late HttpServer server;
    late Uri baseUri;
    late Client client;

    setUpAll(() async {
      dir = io.Directory.systemTemp.createTempSync('functions_io_serve_');
      var public = io.Directory('${dir.path}/public')
        ..createSync(recursive: true);
      io.File('${public.path}/index.html').writeAsStringSync('home');
      io.File('${public.path}/page.html').writeAsStringSync('page');
      io.Directory('${public.path}/sub').createSync();
      io.File('${public.path}/sub/index.html').writeAsStringSync('sub');
      secret = io.File('${dir.path}/secret.txt')..writeAsStringSync('secret');
      firebaseFunctionsIo['echo'] = firebaseFunctionsIo.https.onRequest(
        (request) => request.response.send('echo'),
      );
      server = await serve(port: 0, publicDir: public.path);
      baseUri = Uri.parse('http://localhost:${server.port}/');
      client = httpClientFactoryIo.newClient();
    });
    tearDownAll(() async {
      client.close();
      await server.close(force: true);
      dir.deleteSync(recursive: true);
    });

    Future<(int, String)> get(String path) async {
      var response = await client
          .get(baseUri.replace(path: path))
          .timeout(const Duration(seconds: 5));
      return (response.statusCode, response.body);
    }

    test('files of the public folder', () async {
      expect(await get('/'), (200, 'home'));
      expect(await get('/page.html'), (200, 'page'));
      expect(await get('/sub/'), (200, 'sub'));
      expect(await get('/echo'), (200, 'echo'));
      expect((await get('/missing.html')).$1, 404);
    });

    test('nothing out of the public folder', () async {
      // An absolute path of the machine.
      expect((await get(secret.path)).$1, 404);
      expect((await get('/%2e%2e/secret.txt')).$1, 404);
      expect((await get('/sub/..%2f..%2fsecret.txt')).$1, 404);
    });

    test('publicDirFilePath', () {
      var sep = io.Platform.pathSeparator;
      String? path(String uriPath) =>
          publicDirFilePath(Uri.parse(uriPath), publicDir: 'p');
      expect(path('/'), 'p${sep}index.html');
      expect(path('/a/'), 'p${sep}a${sep}index.html');
      expect(path('/a/b.js'), 'p${sep}a${sep}b.js');
      // Uri decodes then removes the dot segments: still under p.
      expect(path('/%2e%2e/x'), 'p${sep}x');
      expect(path('/a%2Fb'), isNull);
      expect(path('/a%5Cb'), isNull);
      expect(path('/c:/x'), isNull);
      expect(path('/a//b'), isNull);
    });
  });
}
