import 'package:tekartik_app_dev_menu/dev_menu.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_firebase_functions_test/constants.dart';

export 'package:tekartik_app_dev_menu/dev_menu.dart';

/// Top doc context
class FirebaseFunctionsCallMainMenuContext {
  final FirebaseFunctionsCall functionsCall;

  FirebaseFunctionsCallMainMenuContext({required this.functionsCall});
}

void firebaseFunctionsCallMainMenu({
  required FirebaseFunctionsCallMainMenuContext context,
}) {
  var functionsCall = context.functionsCall;
  var callable = functionsCall.callable(callableFunctionTestName);
  menu('call', () {
    item('simple string', () async {
      var result = callable.call<Object>(['simple string sent']);
      write(result);
    });
  });
}
