import 'package:tekartik_app_dev_menu/dev_menu.dart';

int? get httpPortKvValue {
  return int.tryParse(httpPortKv.value ?? '');
}

var httpPortKv = 'firebase_sim_example.http.port'.kvFromVar();

void varsMenu() {
  keyValuesMenu('vars', [httpPortKv]);
}

Future<void> main(List<String> args) async {
  await mainMenu(args, () {
    varsMenu();
  });
}
