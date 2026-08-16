import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studycollection/data/models/notebook.dart';
import 'package:studycollection/data/models/study_session.dart';
import 'package:studycollection/data/repositories/app_state.dart';

void main() {
  test('コレクションには全手帳のピースが表示される', () {
    final firstStartedAt = DateTime(2026, 1, 1);
    final secondStartedAt = DateTime(2026, 1, 2);
    final state = AppState()
      ..notebooks = [
        Notebook(
          id: 'first',
          title: '1冊目',
          theme: 'debug',
          startedAt: firstStartedAt,
          imagePath: 'first.jpg',
        ),
        Notebook(
          id: 'second',
          title: '2冊目',
          theme: 'debug',
          startedAt: secondStartedAt,
          imagePath: 'second.jpg',
        ),
      ]
      ..sessions = [
        StudySession(
          at: firstStartedAt.add(const Duration(seconds: 1)),
          subject: '英語',
          seconds: 10,
          notebookId: 'first',
        ),
        StudySession(
          at: secondStartedAt.add(const Duration(seconds: 1)),
          subject: '数学',
          seconds: 5,
          notebookId: 'second',
        ),
      ];

    final pieces = state.collectionPieces;

    expect(pieces, hasLength(2));
    expect(pieces.map((piece) => piece['imagePath']), [
      'second.jpg',
      'first.jpg',
    ]);
  });

  test('完成後も同じ手帳を使い続けて次のピースを作れる', () async {
    SharedPreferences.setMockInitialValues({});
    final startedAt = DateTime.now().subtract(const Duration(minutes: 1));
    final state = AppState()
      ..notebooks = [
        Notebook(
          id: 'active',
          title: '継続する手帳',
          theme: 'debug',
          startedAt: startedAt,
          imagePath: 'oshi.jpg',
        ),
      ]
      ..activeNotebookId = 'active';

    await state.addSession(subject: '英語', seconds: 10);
    expect(state.activeNotebookId, 'active');
    expect(state.collectionPieces, hasLength(1));
    expect(state.collectionPieces.first['opacity'], 1.0);

    await state.addSession(subject: '英語', seconds: 5);
    expect(state.activeNotebookId, 'active');
    expect(state.collectionPieces, hasLength(2));
    expect(state.collectionPieces.last['opacity'], 0.5);
  });
}
