import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/common_widgets.dart';
import '../../app/formatters.dart';
import '../../app/theme.dart';
import '../../data/models/collection_item.dart';
import '../notebook/notebook_page.dart';
import '../../data/repositories/app_state.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
        children: [
          pageHeader('コレクション', '進行中と完了済みのピースが両方表示されます。'),
          // In-progress pieces derived from sessions
          if (state.derivedPieces.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text('ピース', style: TextStyle(color: muted)),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.65,
              children: state.derivedPieces.map((piece) {
                return GestureDetector(
                  onTap: () => showPieceEditor(context, state, piece),
                  child: Column(
                    children: [
                      Expanded(
                        child: DevelopingPhoto(
                          imagePath: piece['imagePath'] as String?,
                          progress: (piece['opacity'] as double).clamp(0.0, 1.0),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        piece['subject'] as String? ?? '未指定',
                        style: const TextStyle(fontSize: 12, color: ink),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        formatDuration(piece['seconds'] as int),
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
          ],
          if (state.collections.isEmpty)
            const EmptyState(
              icon: CupertinoIcons.square_grid_2x2,
              title: 'コレクションはまだありません',
              message: 'フォトを100%まで完成させると追加されます',
            )
          else
            ...state.collections.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GestureDetector(
                  onTap: () => showCollection(context, item),
                  child: SurfaceCard(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 105,
                          child: DevelopingPhoto(
                            imagePath: item.imagePath,
                            progress: 1,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                formatDate(item.completedAt),
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${formatDuration(item.totalSeconds)}・${item.topSubject}',
                                style: const TextStyle(color: ink),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 18,
                          color: muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void showCollection(BuildContext context, CollectionItem item) {
    // Open the notebook view for this completed collection when possible.
    // Ensure the notebook is selected, then push the NotebookPage so UI matchesホームの手帳。
    state.selectNotebook(item.id).then((_) {
      if (context.mounted) Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NotebookPage(state: state)),
      );
    });
  }

  void showPieceEditor(BuildContext context, AppState state, Map<String, dynamic> piece) {
    final subjectController = TextEditingController(text: piece['subject'] as String?);
    final secondsController = TextEditingController(text: (piece['seconds'] as int).toString());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 22,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ピースを編集', style: const TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            SizedBox(height: 200, child: DevelopingPhoto(imagePath: piece['imagePath'] as String?, progress: (piece['opacity'] as double).clamp(0.0,1.0))),
            const SizedBox(height: 12),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: '教科（未指定可）'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: secondsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'このピースの勉強時間（秒）'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final subject = subjectController.text.trim().isEmpty ? null : subjectController.text.trim();
                      final seconds = int.tryParse(secondsController.text) ?? (piece['seconds'] as int);
                      await state.updatePieceOverride(piece['id'] as String, subject: subject, seconds: seconds);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
