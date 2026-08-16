import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/common_widgets.dart';
import '../../app/theme.dart';
import '../../data/repositories/app_state.dart';

Future<bool> showSubjectManager(BuildContext context, AppState state) async {
  final values = [...state.subjects];
  var pendingSubject = '';

  void addPendingSubject(void Function(VoidCallback fn) setSheetState) {
    final name = pendingSubject.trim();
    if (name.isEmpty || values.contains(name)) return;
    setSheetState(() {
      values.add(name);
      pendingSubject = '';
    });
  }

  final result = await showModalBottomSheet<bool>(
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
              key: ValueKey(values.length),
              decoration: const InputDecoration(
                hintText: '例：英検、古文、情報',
                labelText: '新しい教科',
              ),
              onChanged: (value) => pendingSubject = value,
              onSubmitted: (value) {
                pendingSubject = value;
                addPendingSubject(setSheetState);
              },
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: '保存',
              onPressed: () async {
                addPendingSubject(setSheetState);
                if (values.isEmpty) return;
                await state.updateSubjects(values);
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    ),
  );
  return result == true;
}
