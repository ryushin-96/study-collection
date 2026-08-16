import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/common_widgets.dart';
import '../../app/theme.dart';
import '../../data/models/notebook_theme.dart';
import '../../data/repositories/app_state.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int step = 0;
  String theme = 'heart';
  String? imagePath;
  String? defaultSubject;
  String? notebookTitle = 'わたしのStudy手帳 ♡';
  bool saving = false;
  late TextEditingController _titleController;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (picked == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final extension = picked.path.split('.').last;
    final destination =
        '${directory.path}/oshi_${DateTime.now().millisecondsSinceEpoch}.$extension';
        await File(picked.path).copy(destination);
        // Pre-cache a resized version to avoid heavy first-frame decode
        try {
          if (!mounted) return;
          await precacheImage(ResizeImage(FileImage(File(destination)), width: 1200), context);
        } catch (_) {}
        if (mounted) setState(() => imagePath = destination);
  }

  Future<void> create() async {
    setState(() => saving = true);
    await widget.state.createNotebook(
      selectedTheme: theme,
      selectedImagePath: imagePath,
      defaultSubject: defaultSubject,
      title: _titleController.text,
    );
    if (mounted) setState(() => saving = false);
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: notebookTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: step == 0 ? intro() : photoStep(),
        ),
      ),
    );
  }

  Widget intro() => Column(
    key: const ValueKey('intro'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Brand(),
      const Spacer(),
      const Text(
        '勉強するほど、\n推しが見えてくる。',
        style: TextStyle(
          color: ink,
          fontSize: 34,
          height: 1.25,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'ストップウォッチで勉強した時間を記録。\n白いフォトが少しずつ現像されます。',
        style: TextStyle(color: muted, height: 1.7),
      ),
      const SizedBox(height: 34),
      const _NotebookPreview(),
      const Spacer(),
      PrimaryButton(
        label: 'Study手帳をつくる',
        onPressed: () => setState(() {
          theme = kDebugMode ? 'debug' : 'heart';
          step = 1;
        }),
      ),
    ],
  );

  

  String _goalLabel(NotebookThemeData item) {
    if (item.debugOnly) return '10秒で完成';
    if (item.id == 'heart') return '0〜1時間';
    if (item.id == 'jewel') return '10時間以上';
    return '${item.goalSeconds ~/ 3600}時間';
  }

  Widget photoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        key: const ValueKey('photo'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          setupHeader('推しフォトを\nセットしよう', 1),
          const Text('画像はこの端末の中だけに保存されます。', style: TextStyle(color: muted)),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: '手帳の名前'),
            controller: _titleController,
            onChanged: (v) => notebookTitle = v,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            value: defaultSubject,
            decoration: const InputDecoration(labelText: 'デフォルト教科（未指定可）'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('未指定')),
              ...widget.state.subjects.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s)))
            ],
            onChanged: (v) => setState(() => defaultSubject = v),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: pickImage,
            child: Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE8CBD7), width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: imagePath == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.photo_on_rectangle,
                          size: 42,
                          color: pink,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '写真を選択',
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '未選択でも試せます',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    )
                  : Image.file(File(imagePath!), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: saving ? '作成中…' : 'この手帳をはじめる',
            onPressed: saving ? null : create,
          ),
        ],
      ),
    );
  }
  Widget setupHeader(String title, int active) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: List.generate(
          2,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: index <= active ? 27 : 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: index <= active ? pink : const Color(0xFFDED3DA),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      const SizedBox(height: 22),
      Text(title, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 10),
    ],
  );
}

class _NotebookPreview extends StatelessWidget {
  const _NotebookPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      padding: const EdgeInsets.all(15),
      decoration: themeDecoration('heart'),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(color: Colors.white),
            ),
          ),
          Container(width: 1, margin: const EdgeInsets.all(13), color: line),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  height: 12,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: index == 1
                        ? const Color(0xFFFFE5EE)
                        : const Color(0xFFF1E9EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
