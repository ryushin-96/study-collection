class CollectionItem {
  const CollectionItem({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.theme,
    required this.completedAt,
    required this.totalSeconds,
    required this.topSubject,
  });

  final String id;
  final String title;
  final String? imagePath;
  final String theme;
  final DateTime completedAt;
  final int totalSeconds;
  final String topSubject;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imagePath': imagePath,
    'theme': theme,
    'completedAt': completedAt.toIso8601String(),
    'totalSeconds': totalSeconds,
    'topSubject': topSubject,
  };

  factory CollectionItem.fromJson(Map<String, dynamic> json) => CollectionItem(
    id: json['id'] as String,
    title: json['title'] as String,
    imagePath: json['imagePath'] as String?,
    theme: json['theme'] as String,
    completedAt: DateTime.parse(json['completedAt'] as String),
    totalSeconds: json['totalSeconds'] as int,
    topSubject: json['topSubject'] as String,
  );
}
