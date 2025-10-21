import 'package:tekartik_app_dev_menu/dev_menu.dart';

int? get simPortKvValue {
  return int.tryParse(simPortKv.value ?? '');
}

int? get httpPortKvValue {
  return int.tryParse(httpPortKv.value ?? '');
}

var simPortKv = 'function_sim_example.all.sim.port'.kvFromVar();
var httpPortKv = 'firebase_sim_example.all.http.port'.kvFromVar();

void varsMenu() {
  keyValuesMenu('vars', [simPortKv, httpPortKv]);
}

Future<void> main(List<String> args) async {
  await mainMenu(args, () {
    varsMenu();
  });
}
