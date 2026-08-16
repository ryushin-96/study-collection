import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/common_widgets.dart';
import '../../app/theme.dart';
import '../../data/repositories/app_state.dart';

Future<void> showSubjectManager(BuildContext context, AppState state) async {
  final values = [...state.subjects];
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '教科を管理',
              style: TextStyle(
                color: ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            ...values.asMap().entries.map(
              (entry) => ListTile(
                title: Text(entry.value),
                trailing: IconButton(
                  icon: const Icon(CupertinoIcons.trash),
                  onPressed: () =>
                      setSheetState(() => values.removeAt(entry.key)),
                ),
              ),
            ),
            TextField(
              decoration: const InputDecoration(
                hintText: '例：英検、古文、情報',
                labelText: '新しい教科',
              ),
              onSubmitted: (value) {
                final name = value.trim();
                if (name.isNotEmpty && !values.contains(name)) {
                  setSheetState(() => values.add(name));
                }
              },
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: '保存',
              onPressed: () async {
                if (values.isEmpty) return;
                await state.updateSubjects(values);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
