class Notebook {
  const Notebook({
    required this.id,
    required this.title,
    required this.theme,
    required this.startedAt,
    this.imagePath,
    this.defaultSubject,
    this.note,
    this.completedAt,
  });

  final String id;
  final String title;
  final String theme;
  final DateTime startedAt;
  final String? imagePath;
  final String? defaultSubject;
  final String? note;
  final DateTime? completedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'theme': theme,
    'startedAt': startedAt.toIso8601String(),
    'imagePath': imagePath,
    'defaultSubject': defaultSubject,
    'note': note,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory Notebook.fromJson(Map<String, dynamic> json) => Notebook(
    id: json['id'] as String,
    title: json['title'] as String,
    theme: json['theme'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    imagePath: json['imagePath'] as String?,
    defaultSubject: json['defaultSubject'] as String?,
    note: json['note'] as String?,
    completedAt: json['completedAt'] == null ? null : DateTime.tryParse(json['completedAt'] as String),
  );
}
