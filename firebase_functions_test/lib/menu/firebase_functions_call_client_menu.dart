import 'package:tekartik_app_dev_menu/dev_menu.dart';
import 'package:tekartik_firebase_functions_call/functions_call.dart';
import 'package:tekartik_firebase_functions_test/constants.dart';
import 'package:tekartik_firebase_functions_test/firebase_functions_test.dart';

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
  var client = CallFunctionTestClient(callable);
  menu('call', () {
    item('simple string', () async {
      var input = FunctionTestInputData(
        command: testCommandData,
        data: 'simple string sent',
      );
      write('Sending ${input.toMap()}');
      var output = await client.send(input);
      var result = output.data;
      write('Result: $result');
    });
    item('current user', () async {
      var input = FunctionTestInputData(command: testCommandUserId);
      var output = await client.send(input);
      var result = output.data;
      write('uid: $result');
    });
    item('current projectId', () async {
      write('app projectId: ${functionsCall.app.options.projectId}');
      var input = FunctionTestInputData(command: testCommandProjectId);
      var output = await client.send(input);
      var result = output.data;

      write('functions projectId: $result');
    });
  });
}
