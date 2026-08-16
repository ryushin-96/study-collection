import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/common_widgets.dart';
import '../../app/theme.dart';
import '../../data/repositories/app_state.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final pieces = state.collectionPieces;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
          children: [
            pageHeader('コレクション', '勉強して集めたピースが表示されます。'),
            if (pieces.isNotEmpty) ...[
              const SizedBox(height: 6),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 7,
                crossAxisSpacing: 7,
                childAspectRatio: 0.72,
                children: pieces.map((piece) {
                  return GestureDetector(
                    onTap: () => showPieceEditor(context, state, piece),
                    child: DevelopingPhoto(
                      imagePath: piece['imagePath'] as String?,
                      progress: (piece['opacity'] as double).clamp(0.0, 1.0),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (pieces.isEmpty)
              const EmptyState(
                icon: CupertinoIcons.square_grid_2x2,
                title: 'ピースはまだありません',
                message: '勉強を記録するとピースが追加されます',
              ),
          ],
        );
      },
    );
  }

  void showPieceEditor(
    BuildContext context,
    AppState state,
    Map<String, dynamic> piece,
  ) {
    final secondsController = TextEditingController(
      text: (piece['seconds'] as int).toString(),
    );
    final currentSubject = piece['subject'] as String?;
    String? selectedSubject = state.subjects.contains(currentSubject)
        ? currentSubject
        : state.subjects.firstOrNull;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
              Text(
                'ピースを編集',
                style: const TextStyle(
                  color: ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: DevelopingPhoto(
                  imagePath: piece['imagePath'] as String?,
                  progress: (piece['opacity'] as double).clamp(0.0, 1.0),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedSubject,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '教科'),
                items: state.subjects
                    .map(
                      (subject) => DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setSheetState(() => selectedSubject = value),
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
                        final seconds =
                            int.tryParse(secondsController.text) ??
                            (piece['seconds'] as int);
                        await state.updatePieceOverride(
                          piece['id'] as String,
                          subject: selectedSubject,
                          seconds: seconds,
                        );
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
      ),
    );
  }
}
