import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'data/repositories/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  runApp(StudyCollectionApp(state: state));
}
