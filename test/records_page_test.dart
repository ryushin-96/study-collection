import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studycollection/data/models/notebook.dart';
import 'package:studycollection/data/models/study_session.dart';
import 'package:studycollection/data/repositories/app_state.dart';
import 'package:studycollection/features/records/records_page.dart';

void main() {
  testWidgets('手帳を選ぶと統計と記録が絞り込まれる', (tester) async {
    final now = DateTime.now();
    final state = AppState()
      ..notebooks = [
        Notebook(
          id: 'english',
          title: '英語の手帳',
          theme: 'heart',
          startedAt: now.subtract(const Duration(days: 2)),
        ),
        Notebook(
          id: 'math',
          title: '数学の手帳',
          theme: 'heart',
          startedAt: now.subtract(const Duration(days: 1)),
        ),
      ]
      ..sessions = [
        StudySession(
          at: now,
          subject: '英語',
          seconds: 3600,
          notebookId: 'english',
        ),
        StudySession(at: now, subject: '数学', seconds: 7200, notebookId: 'math'),
      ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RecordsPage(state: state)),
      ),
    );

    expect(find.text('3時間'), findsNWidgets(3));
    expect(find.text('英語'), findsWidgets);
    expect(find.text('数学'), findsWidgets);

    await tester.tap(find.text('すべての手帳'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('数学の手帳').last);
    await tester.pumpAndSettle();

    expect(find.text('2時間'), findsNWidgets(4));
    expect(find.text('英語'), findsNothing);
    expect(find.text('数学'), findsWidgets);
    expect(find.text('この手帳の記録'), findsOneWidget);
  });
}
