String formatClock(int seconds) {
  final minutes = seconds ~/ 60;
  final remain = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remain.toString().padLeft(2, '0')}';
}

String formatDuration(int seconds) {
  if (seconds < 60) return '$seconds秒';
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '$minutes分';
  final hours = minutes ~/ 60;
  final remain = minutes % 60;
  return remain == 0 ? '$hours時間' : '$hours時間$remain分';
}

String formatDate(DateTime value) =>
    '${value.year}/${value.month}/${value.day}';

extension FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
