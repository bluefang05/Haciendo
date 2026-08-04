import 'package:flutter/material.dart';

import 'app/app_state.dart';
import 'app/haciendo_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  runApp(HaciendoApp(state: state));
  await state.initialize();
}
