import 'package:flutter/material.dart';

import '../../app/common_widgets.dart';
import '../../app/formatters.dart';
import '../../app/theme.dart';
import '../../data/repositories/app_state.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final now = DateTime.now();
        final today = state.sessions
            .where(
              (item) =>
                  item.at.year == now.year &&
                  item.at.month == now.month &&
                  item.at.day == now.day,
            )
            .fold(0, (total, item) => total + item.seconds);
        final weekStart = now.subtract(const Duration(days: 7));
        final week = state.sessions
            .where((item) => item.at.isAfter(weekStart))
            .fold(0, (total, item) => total + item.seconds);
        final all = state.sessions.fold(
          0,
          (total, item) => total + item.seconds,
        );
        final bySubject = <String, int>{};
        for (final item in state.sessions) {
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
            sectionTitle('すべての記録'),
            ...state.sessions.reversed.map(sessionTile),
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
