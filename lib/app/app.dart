import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/repositories/app_state.dart';
import '../features/onboarding/setup_screen.dart';
import 'main_shell.dart';
import 'theme.dart';

class StudyCollectionApp extends StatelessWidget {
  const StudyCollectionApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '推しとStudy',
      theme: buildAppTheme(),
      home: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          if (!state.initialized) {
            return const Scaffold(
              body: Center(child: CupertinoActivityIndicator()),
            );
          }
          return state.ready
              ? MainShell(state: state)
              : SetupScreen(state: state);
        },
      ),
    );
  }
}
