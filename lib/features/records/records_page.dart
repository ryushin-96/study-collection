import 'package:flutter/material.dart';

import '../../app/common_widgets.dart';
import '../../app/formatters.dart';
import '../../app/theme.dart';
import '../../data/repositories/app_state.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key, required this.state});

  final AppState state;

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  String? selectedNotebookId;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        if (selectedNotebookId != null &&
            !state.notebooks.any(
              (notebook) => notebook.id == selectedNotebookId,
            )) {
          selectedNotebookId = null;
        }
        final filteredSessions = selectedNotebookId == null
            ? state.sessions
            : state.sessions
                  .where((session) => session.notebookId == selectedNotebookId)
                  .toList();
        final now = DateTime.now();
        final today = filteredSessions
            .where(
              (item) =>
                  item.at.year == now.year &&
                  item.at.month == now.month &&
                  item.at.day == now.day,
            )
            .fold(0, (total, item) => total + item.seconds);
        final weekStart = now.subtract(const Duration(days: 7));
        final week = filteredSessions
            .where((item) => item.at.isAfter(weekStart))
            .fold(0, (total, item) => total + item.seconds);
        final all = filteredSessions.fold(
          0,
          (total, item) => total + item.seconds,
        );
        final bySubject = <String, int>{};
        for (final item in filteredSessions) {
          bySubject[item.subject] =
              (bySubject[item.subject] ?? 0) + item.seconds;
        }
        final maxSeconds = bySubject.values.fold<int>(
          1,
          (a, b) => a > b ? a : b,
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
          children: [
            pageHeader('勉強きろく', '時間もしっかり残ります。'),
            DropdownButtonFormField<String?>(
              key: ValueKey(
                'notebook-filter-${state.notebooks.map((notebook) => notebook.id).join('-')}',
              ),
              initialValue: selectedNotebookId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '手帳で絞り込む'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('すべての手帳'),
                ),
                ...state.notebooks.reversed.map(
                  (notebook) => DropdownMenuItem<String?>(
                    value: notebook.id,
                    child: Text(
                      notebook.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => selectedNotebookId = value),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatCard(label: '今日', value: formatDuration(today)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(label: '今週', value: formatDuration(week)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(label: '合計', value: formatDuration(all)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle('教科別の勉強時間'),
                  const SizedBox(height: 12),
                  if (bySubject.isEmpty)
                    const Text(
                      '記録するとグラフが表示されます。',
                      style: TextStyle(color: muted),
                    )
                  else
                    ...bySubject.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 13),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  formatDuration(entry.value),
                                  style: const TextStyle(color: muted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            LinearProgressIndicator(
                              value: entry.value / maxSeconds,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(20),
                              color: subjectColor(entry.key),
                              backgroundColor: const Color(0xFFF2EBEF),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            sectionTitle(selectedNotebookId == null ? 'すべての記録' : 'この手帳の記録'),
            ...filteredSessions.reversed.map(sessionTile),
            if (filteredSessions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'この手帳にはまだ記録がありません。',
                  style: TextStyle(color: muted),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: muted, fontSize: 10)),
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
