import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/common_widgets.dart';
import '../../app/formatters.dart';
import '../../app/theme.dart';
import '../../data/models/notebook_theme.dart';
import '../../data/repositories/app_state.dart';
import '../study_timer/study_timer_page.dart';
import '../subjects/subject_manager.dart';

class NotebookPage extends StatefulWidget {
  const NotebookPage({super.key, required this.state});

  final AppState state;

  @override
  State<NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends State<NotebookPage> {
  String? selectedSubject;
  bool countdown = false;
  int countdownSeconds = 1500;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    selectedSubject ??= state.subjects.firstOrNull;

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final display = state.displayNotebook;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            if (state.notebooks.isEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Brand(),
                  TextButton(
                    onPressed: () async {
                      await showCreateNotebookDialog(context, state);
                    },
                    child: const Text('新しい手帳を作る'),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Material(
                      type: MaterialType.transparency,
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: display?.id,
                        decoration: const InputDecoration(border: InputBorder.none),
                        items: state.notebooks
                            .map((n) => DropdownMenuItem<String?>(
                                  value: n.id,
                                  child: Text(
                                    n.title,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) async {
                          if (v != null) await state.selectNotebook(v);
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: display == null
                        ? null
                        : () async {
                            final confirmDelete = await confirm(
                              context,
                              title: '手帳を削除しますか？',
                              message: 'この手帳と関連する記録・画像は削除されます。',
                              actionLabel: '削除する',
                            );
                            if (!confirmDelete) return;
                            final id = display.id;
                            await state.deleteNotebook(id);
                          },
                    icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent),
                    tooltip: '選択中の手帳を削除',
                  ),
                  TextButton(
                    onPressed: () async {
                      await showCreateNotebookDialog(context, state);
                    },
                    child: const Text('＋ 新規'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            _NotebookCard(state: state, onEditTitle: editTitle),
            // Share button removed until implemented
            const SizedBox(height: 20),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '今日は何を勉強する？',
                    style: TextStyle(color: ink, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 13),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('ストップウォッチ')),
                      ButtonSegment(value: true, label: Text('タイマー')),
                    ],
                    selected: {countdown},
                    onSelectionChanged: (value) => setState(() => countdown = value.first),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    type: MaterialType.transparency,
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedSubject,
                      decoration: const InputDecoration(labelText: '教科'),
                      items: state.subjects
                          .map(
                            (subject) => DropdownMenuItem(
                              value: subject,
                              child: Text(subject),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => selectedSubject = value),
                    ),
                  ),
                  if (countdown) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: countdownSeconds,
                      decoration: const InputDecoration(labelText: '集中時間'),
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('10秒・POC用')),
                        DropdownMenuItem(value: 900, child: Text('15分')),
                        DropdownMenuItem(value: 1500, child: Text('25分')),
                        DropdownMenuItem(value: 1800, child: Text('30分')),
                        DropdownMenuItem(value: 2700, child: Text('45分')),
                        DropdownMenuItem(value: 3600, child: Text('60分')),
                      ],
                      onChanged: (value) => setState(() => countdownSeconds = value ?? 1500),
                    ),
                  ],
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: countdown ? 'タイマーを始める' : 'ストップウォッチを始める',
                    onPressed: selectedSubject == null
                        ? null
                        : () => Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => StudyTimerPage(
                                state: state,
                                subject: selectedSubject!,
                                countdownSeconds: countdown ? countdownSeconds : null,
                              ),
                            ),
                          ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await showSubjectManager(context, state);
                      if (mounted) {
                        setState(() => selectedSubject = state.subjects.firstOrNull);
                      }
                    },
                    child: const Text('＋ 教科の追加・編集・削除'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            sectionTitle('最近の勉強'),
            ...state.currentNotebookSessions.reversed.take(3).map(sessionTile),
            if (state.currentNotebookSessions.isEmpty)
              const EmptyState(
                icon: CupertinoIcons.timer,
                title: 'まだ記録がありません',
                message: '最初のストップウォッチを始めよう',
              ),
          ],
        );
      },
    );
  }

  Future<void> editTitle() async {
    final display = widget.state.displayNotebook;
    final controller = TextEditingController(text: display?.title ?? widget.state.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手帳タイトルを編集'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(hintText: 'わたしのStudy手帳 ♡'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await widget.state.updateTitle(result, notebookId: display?.id);
    }
  }

  Future<void> showCreateNotebookDialog(BuildContext context, AppState state) async {
    final titleController = TextEditingController(text: 'わたしのStudy手帳 ♡');
    String? defaultSubject = state.subjects.firstOrNull;
    String? selectedImagePath;

    Future<void> pickImage(StateSetter setLocalState) async {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1800,
      );
      if (picked == null) return;
      final directory = await getApplicationDocumentsDirectory();
      final extension = picked.path.split('.').last;
      final destination = '${directory.path}/oshi_${DateTime.now().millisecondsSinceEpoch}.$extension';
      await File(picked.path).copy(destination);
      try {
        if (!mounted) return;
        await precacheImage(ResizeImage(FileImage(File(destination)), width: 1200), context);
      } catch (_) {}
      setLocalState(() => selectedImagePath = destination);
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final mq = MediaQuery.of(context);
        final maxH = mq.size.height * 0.6;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: StatefulBuilder(
              builder: (context, setLocalState) {
                final kb = MediaQuery.of(context).viewInsets.bottom;
                final imageHeight = kb > 0 ? 88.0 : 120.0;
                return Padding(
                  padding: EdgeInsets.only(bottom: kb),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('新しい手帳を作成', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        TextField(controller: titleController, decoration: const InputDecoration(labelText: 'タイトル')),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          value: defaultSubject,
                          decoration: const InputDecoration(labelText: 'デフォルト教科（未指定可）'),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('未指定')),
                            ...state.subjects.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s)))
                          ],
                          onChanged: (v) => setLocalState(() => defaultSubject = v),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => pickImage(setLocalState),
                          child: Container(
                            height: imageHeight,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE8CBD7), width: 2),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: selectedImagePath == null
                                ? const Center(
                                    child: Text('写真を選択（オプション）', style: TextStyle(color: muted)),
                                  )
                                : Image.file(File(selectedImagePath!), fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                            const SizedBox(width: 8),
                            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('作成')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (result == true) {
      await state.createNotebook(
        selectedTheme: kDebugMode ? 'debug' : 'heart',
        selectedImagePath: selectedImagePath,
        defaultSubject: defaultSubject,
        title: titleController.text,
      );
    }
  }
}

class _NotebookCard extends StatelessWidget {
  const _NotebookCard({required this.state, required this.onEditTitle});

  final AppState state;
  final VoidCallback onEditTitle;

  @override
  Widget build(BuildContext context) {
    final nb = state.displayNotebook;
    final displayTitle = nb?.title ?? state.title;
    final themeData = nb != null
        ? notebookThemes.firstWhere((t) => t.id == nb.theme, orElse: () => notebookThemes.firstWhere((it) => it.id == 'heart'))
        : state.currentTheme;
    final imagePath = nb != null ? state.notebookDisplayImagePath(nb) : state.activeImagePath;
    final progress = nb != null ? state.notebookProgressFor(nb) : state.progress;
    final seconds = nb != null ? state.notebookSecondsFor(nb) : state.notebookSeconds;
    final topSubject = nb != null ? state.topSubjectFor(nb) : state.topSubject;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: themeDecoration(nb?.theme ?? state.theme),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'MY OSHI PHOTO',
                    style: TextStyle(
                      color: muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                DevelopingPhoto(
                  imagePath: imagePath,
                  progress: progress,
                ),
                const SizedBox(height: 7),
                Text(
                  progress >= 1.0 ? '100%・完成 ♡' : '${(progress * 100).round()}%・あと${formatDuration(themeData.goalSeconds - seconds)}',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 255,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: line,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STUDY MEMORY',
                  style: TextStyle(
                    color: muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        displayTitle,
                        style: const TextStyle(
                          color: ink,
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w900,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    IconButton(
                      onPressed: onEditTitle,
                      visualDensity: VisualDensity.compact,
                      iconSize: 17,
                      icon: const Icon(CupertinoIcons.pencil, color: pink),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _stat('STUDY', formatDuration(seconds)),
                _stat('TOP SUBJECT', topSubject),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                if ((nb?.note ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    nb!.note!,
                    style: const TextStyle(color: ink),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                TextButton(
                  onPressed: () async {
                    final controller = TextEditingController(text: nb?.note ?? '');
                    final res = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('手帳メモを編集'),
                        content: TextField(
                          controller: controller,
                          minLines: 3,
                          maxLines: 8,
                          decoration: const InputDecoration(hintText: '今日の気づきやメモをここに書いてください'),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('保存')),
                        ],
                      ),
                    );
                    if (res == true) {
                      await state.updateNotebookNote(controller.text.trim().isEmpty ? null : controller.text.trim(), notebookId: nb?.id);
                    }
                  },
                  child: const Text('手帳メモを編集'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 8)),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}
