import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studycollection/app/app.dart';
import 'package:studycollection/data/repositories/app_state.dart';
import 'package:studycollection/features/study_timer/study_timer_page.dart';

void main() {
  testWidgets('初回画面にアプリの価値が表示される', (tester) async {
    final state = AppState();
    state.initialized = true;
    await tester.pumpWidget(StudyCollectionApp(state: state));
    await tester.pump();

    expect(find.text('勉強するほど、\n推しが見えてくる。'), findsOneWidget);
    expect(find.text('Study手帳をつくる'), findsOneWidget);
  });

  testWidgets('手帳選択に10秒デバッグが表示される', (tester) async {
    final state = AppState()..initialized = true;
    await tester.pumpWidget(StudyCollectionApp(state: state));

    await tester.tap(find.text('Study手帳をつくる'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('10秒デバッグ'), findsOneWidget);
    expect(find.text('10秒で完成'), findsOneWidget);
  });

  testWidgets('計測を記録せず取り消せる', (tester) async {
    final state = AppState()..initialized = true;
    await tester.pumpWidget(
      MaterialApp(
        home: StudyTimerPage(
          state: state,
          subject: '英語',
          countdownSeconds: null,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('終了して記録'), findsOneWidget);
    expect(find.text('一時停止'), findsOneWidget);
    expect(find.text('記録せず取り消す'), findsOneWidget);
  });
}
