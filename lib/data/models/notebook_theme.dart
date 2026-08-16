class NotebookThemeData {
  const NotebookThemeData({
    required this.id,
    required this.name,
    required this.goalSeconds,
    required this.mark,
    this.debugOnly = false,
  });

  final String id;
  final String name;
  final int goalSeconds;
  final String mark;
  final bool debugOnly;
}

const notebookThemes = <NotebookThemeData>[
  NotebookThemeData(
    id: 'debug',
    name: '10秒デバッグ',
    goalSeconds: 10,
    mark: 'DEBUG',
    debugOnly: true,
  ),
  NotebookThemeData(id: 'heart', name: '放課後ハート', goalSeconds: 3600, mark: '♡'),
  NotebookThemeData(
    id: 'ribbon',
    name: 'リボンチェック',
    goalSeconds: 14400,
    mark: '୨୧',
  ),
  NotebookThemeData(
    id: 'lace',
    name: 'きらめきレース',
    goalSeconds: 28800,
    mark: '♡ ✦',
  ),
  NotebookThemeData(
    id: 'jewel',
    name: 'プリンセスジュエル',
    goalSeconds: 36000,
    mark: '♔ ୨୧',
  ),
];
