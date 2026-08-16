class StudySession {
  const StudySession({
    required this.at,
    required this.subject,
    required this.seconds,
    this.notebookId,
  });

  final DateTime at;
  final String subject;
  final int seconds;
  final String? notebookId;

  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'subject': subject,
    'seconds': seconds,
    'notebookId': notebookId,
  };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
    at: DateTime.parse(json['at'] as String),
    subject: json['subject'] as String,
    seconds: json['seconds'] as int,
    notebookId: json['notebookId'] as String?,
  );
}
