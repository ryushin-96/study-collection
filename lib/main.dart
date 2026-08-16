import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'data/repositories/app_state.dart';
import 'services/monetization_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  unawaited(MonetizationController.instance.initialize());
  runApp(StudyCollectionApp(state: state));
}
