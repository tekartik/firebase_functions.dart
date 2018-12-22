import 'package:path/path.dart';
import 'package:tekartik_http/http.dart';
import 'package:meta/meta.dart';
import 'package:tekartik_firebase_functions/firebase_functions.dart';

echoHandler(ExpressHttpRequest request) {
  // print("request.url ${request.uri}");
  //request.response.write(requestBodyAsText(request.body));
  //request.response.close();
  request.response.send(requestBodyAsText(request.body));
}

echoQueryHandler(ExpressHttpRequest request) {
  // print("request.url ${request.uri} ${request.uri.queryParameters}");
  request.response.send(request.uri.query);
}

echoFragmentHandler(ExpressHttpRequest request) {
  // print("request.url ${request.uri} ${request.uri.fragment}");
  request.response.send(request.uri.fragment);
}

class TestContext {
  String baseUrl;
}

void setup(
    {@required FirebaseFunctions firebaseFunctions,
    @required HttpClientFactory httpClientFactory,
    @required TestContext context}) {
  redirectFragmentHandler(ExpressHttpRequest request) {
    // print("request.url ${request.uri} ${request.uri.fragment}");
    request.response.redirect(Uri.parse(url.join(context.baseUrl, 'echo')));
  }

  firebaseFunctions['echo'] = firebaseFunctions.https.onRequest(echoHandler);
  firebaseFunctions['redirect'] =
      firebaseFunctions.https.onRequest(redirectFragmentHandler);
  firebaseFunctions['echoQuery'] =
      firebaseFunctions.https.onRequest(echoQueryHandler);
  firebaseFunctions['echoFragment'] =
      firebaseFunctions.https.onRequest(echoFragmentHandler);
}
