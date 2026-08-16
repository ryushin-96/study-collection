import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/collection_item.dart';
import '../models/notebook.dart';
import '../models/notebook_theme.dart';
import '../models/study_session.dart';
import '../storage/image_storage.dart';

class AppState extends ChangeNotifier {
  static const _storageKey = 'study_collection_state_v1';

  bool initialized = false;
  bool ready = false;
  // legacy root fields (kept for compatibility/migration)
  String title = 'わたしのStudy手帳 ♡';
  String theme = 'heart';
  String? imagePath;
  DateTime? notebookStartedAt;
  List<String> subjects = ['英語', '数学', '国語', '理科', '社会'];
  List<StudySession> sessions = [];
  List<CollectionItem> collections = [];
  // multiple notebooks support
  List<Notebook> notebooks = [];
  String? activeNotebookId;
  Notebook? get activeNotebook {
    try {
      return notebooks.firstWhere((n) => n.id == activeNotebookId);
    } catch (_) {
      return null;
    }
  }

  String? get activeImagePath => activeNotebook?.imagePath ?? imagePath;
  // pieceOverrides stores per-piece user edits (subject, seconds, ...)
  Map<String, Map<String, dynamic>> pieceOverrides = {};

  NotebookThemeData get currentTheme => notebookThemes.firstWhere(
    (item) => item.id == (activeNotebook?.theme ?? theme),
    orElse: () => notebookThemes.firstWhere((item) => item.id == 'heart'),
  );

  /// Choose which notebook to display on home: prefer active, then most
  /// recently used via sessions, then last created notebook.
  Notebook? get displayNotebook {
    if (activeNotebook != null) return activeNotebook;
    if (sessions.isNotEmpty) {
      final last = sessions.reduce((a, b) => a.at.isAfter(b.at) ? a : b);
      final nbId = last.notebookId;
      if (nbId != null) {
        try {
          return notebooks.firstWhere((n) => n.id == nbId);
        } catch (_) {}
      }
    }
    if (notebooks.isNotEmpty) return notebooks.last;
    return null;
  }

  /// Sum seconds for a given notebook (only sessions after notebook.startedAt)
  int notebookSecondsFor(Notebook nb) => sessions
      .where((s) => s.notebookId == nb.id && !s.at.isBefore(nb.startedAt))
      .fold(0, (t, s) => t + s.seconds);

  /// Progress (0..1) for a specific notebook
  double notebookProgressFor(Notebook nb) {
    final goal = notebookThemes
        .firstWhere(
          (t) => t.id == nb.theme,
          orElse: () => notebookThemes.firstWhere((it) => it.id == 'heart'),
        )
        .goalSeconds;
    if (goal <= 0) return 0;
    return (notebookSecondsFor(nb) / goal).clamp(0, 1).toDouble();
  }

  /// Whether a notebook is completed
  bool isNotebookCompleted(Notebook nb) => notebookProgressFor(nb) >= 1.0;

  /// Top subject for a given notebook
  String topSubjectFor(Notebook nb) {
    final totals = <String, int>{};
    for (final session in sessions.where(
      (s) => s.notebookId == nb.id && !s.at.isBefore(nb.startedAt),
    )) {
      totals[session.subject] =
          (totals[session.subject] ?? 0) + session.seconds;
    }
    if (totals.isEmpty) return 'まだなし';
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  /// Image path to display for a notebook: if completed, prefer collection image.
  String? notebookDisplayImagePath(Notebook nb) {
    final id = nb.startedAt.millisecondsSinceEpoch.toString();
    try {
      final c = collections.firstWhere((c) => c.id == id);
      return c.imagePath;
    } catch (_) {
      return nb.imagePath;
    }
  }

  List<StudySession> get currentNotebookSessions {
    final active = activeNotebook;
    if (active == null) return const [];
    final startedAt = active.startedAt;
    return sessions
        .where(
          (session) =>
              session.notebookId == active.id &&
              !session.at.isBefore(startedAt),
        )
        .toList();
  }

  int get notebookSeconds => currentNotebookSessions.fold(
    0,
    (total, session) => total + session.seconds,
  );

  double get progress =>
      (notebookSeconds / currentTheme.goalSeconds).clamp(0, 1);

  bool get completed => progress >= 1;

  String get topSubject {
    final totals = <String, int>{};
    for (final session in currentNotebookSessions) {
      totals[session.subject] =
          (totals[session.subject] ?? 0) + session.seconds;
    }
    if (totals.isEmpty) return 'まだなし';
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  Future<void> load() async {
    await ImageStorage.initialize();
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    var imagePathsMigrated = false;
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        ready = json['ready'] as bool? ?? false;
        title = json['title'] as String? ?? title;
        theme = json['theme'] as String? ?? theme;
        imagePath = json['imagePath'] as String?;
        final startedAt = json['notebookStartedAt'] as String?;
        notebookStartedAt = startedAt == null
            ? null
            : DateTime.tryParse(startedAt);
        subjects =
            (json['subjects'] as List<dynamic>?)
                ?.map((item) => item as String)
                .toList() ??
            subjects;
        sessions =
            (json['sessions'] as List<dynamic>?)
                ?.map(
                  (item) => StudySession.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];
        collections =
            (json['collections'] as List<dynamic>?)
                ?.map(
                  (item) =>
                      CollectionItem.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];
        // load notebooks if present (new schema)
        notebooks =
            (json['notebooks'] as List<dynamic>?)
                ?.map((n) => Notebook.fromJson(n as Map<String, dynamic>))
                .toList() ??
            [];
        activeNotebookId = json['activeNotebookId'] as String?;
        // migration: if notebooks empty but legacy notebookStartedAt exists, create one
        if (notebooks.isEmpty && notebookStartedAt != null) {
          final id = notebookStartedAt!.millisecondsSinceEpoch.toString();
          final nb = Notebook(
            id: id,
            title: title,
            theme: theme,
            startedAt: notebookStartedAt!,
            imagePath: imagePath,
            defaultSubject: null,
            note: null,
          );
          notebooks = [nb];
          activeNotebookId = id;
          // assign sessions without notebookId to this notebook
          sessions = sessions
              .map(
                (s) => s.notebookId == null
                    ? StudySession(
                        at: s.at,
                        subject: s.subject,
                        seconds: s.seconds,
                        notebookId: id,
                      )
                    : s,
              )
              .toList();
        }
        // load pieceOverrides if present
        pieceOverrides =
            (json['pieceOverrides'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(
                k,
                (v as Map<String, dynamic>).map((kk, vv) => MapEntry(kk, vv)),
              ),
            ) ??
            {};
        imagePathsMigrated = await _migrateStoredImagePaths();
      } catch (_) {
        // 壊れたローカルデータは初期状態から再開する。
      }
    }
    if (imagePathsMigrated) await save();
    initialized = true;
    notifyListeners();
  }

  Future<bool> _migrateStoredImagePaths() async {
    var changed = false;

    final migratedLegacyPath = await ImageStorage.migrate(imagePath);
    changed |= migratedLegacyPath != imagePath;
    imagePath = migratedLegacyPath;

    final migratedNotebooks = <Notebook>[];
    for (final notebook in notebooks) {
      final migratedPath = await ImageStorage.migrate(notebook.imagePath);
      changed |= migratedPath != notebook.imagePath;
      migratedNotebooks.add(
        Notebook(
          id: notebook.id,
          title: notebook.title,
          theme: notebook.theme,
          startedAt: notebook.startedAt,
          imagePath: migratedPath,
          defaultSubject: notebook.defaultSubject,
          note: notebook.note,
          completedAt: notebook.completedAt,
        ),
      );
    }
    notebooks = migratedNotebooks;

    final migratedCollections = <CollectionItem>[];
    for (final item in collections) {
      final migratedPath = await ImageStorage.migrate(item.imagePath);
      changed |= migratedPath != item.imagePath;
      migratedCollections.add(
        CollectionItem(
          id: item.id,
          title: item.title,
          imagePath: migratedPath,
          theme: item.theme,
          completedAt: item.completedAt,
          totalSeconds: item.totalSeconds,
          topSubject: item.topSubject,
        ),
      );
    }
    collections = migratedCollections;
    return changed;
  }

  Future<void> save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode({
        'ready': ready,
        'title': title,
        'theme': theme,
        'imagePath': imagePath,
        'notebookStartedAt': notebookStartedAt?.toIso8601String(),
        'subjects': subjects,
        'sessions': sessions.map((item) => item.toJson()).toList(),
        'collections': collections.map((item) => item.toJson()).toList(),
        'pieceOverrides': pieceOverrides,
        'notebooks': notebooks.map((n) => n.toJson()).toList(),
        'activeNotebookId': activeNotebookId,
      }),
    );
  }

  /// Generate derived pieces from `sessions` grouped by `currentTheme.goalSeconds`.
  /// Each piece has: id, imagePath, opacity (0..1), subject, seconds, index
  List<Map<String, dynamic>> get derivedPieces {
    Notebook active;
    if (activeNotebook != null) {
      active = activeNotebook!;
    } else {
      if (notebooks.isEmpty) return [];
      active = notebooks.last;
    }
    return _piecesForNotebook(active);
  }

  /// All pieces across every notebook, newest notebooks first. This is kept
  /// separate from [derivedPieces], which represents the currently displayed
  /// notebook and is used by notebook-specific screens.
  List<Map<String, dynamic>> get collectionPieces {
    final orderedNotebooks = [...notebooks]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return orderedNotebooks.expand(_piecesForNotebook).toList(growable: false);
  }

  List<Map<String, dynamic>> _piecesForNotebook(Notebook active) {
    final startedAt = active.startedAt;
    final goal = notebookThemes
        .firstWhere(
          (t) => t.id == active.theme,
          orElse: () => notebookThemes.firstWhere((it) => it.id == 'heart'),
        )
        .goalSeconds;
    if (goal <= 0) return [];

    final sess =
        sessions
            .where(
              (s) => s.notebookId == active.id && !s.at.isBefore(startedAt),
            )
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at));

    final List<Map<String, dynamic>> buckets = [];
    int remainingCapacity = goal;
    final Map<String, int> bucketTotals = {};
    int bucketFilled = 0;

    for (final s in sess) {
      var rem = s.seconds;
      while (rem > 0) {
        final alloc = rem <= remainingCapacity ? rem : remainingCapacity;
        bucketTotals[s.subject] = (bucketTotals[s.subject] ?? 0) + alloc;
        bucketFilled += alloc;
        rem -= alloc;
        remainingCapacity -= alloc;
        if (remainingCapacity == 0) {
          // finalize full bucket
          final top = bucketTotals.entries.isEmpty
              ? 'まだなし'
              : bucketTotals.entries
                    .reduce((a, b) => a.value >= b.value ? a : b)
                    .key;
          buckets.add({'seconds': bucketFilled, 'subject': top});
          // reset
          remainingCapacity = goal;
          bucketTotals.clear();
          bucketFilled = 0;
        }
      }
    }
    // partial bucket
    if (bucketFilled > 0) {
      final top = bucketTotals.entries.isEmpty
          ? 'まだなし'
          : bucketTotals.entries
                .reduce((a, b) => a.value >= b.value ? a : b)
                .key;
      buckets.add({'seconds': bucketFilled, 'subject': top});
    }

    final List<Map<String, dynamic>> pieces = [];
    for (var i = 0; i < buckets.length; i++) {
      final b = buckets[i];
      final id = '${startedAt.millisecondsSinceEpoch}_piece_$i';
      final seconds = b['seconds'] as int;
      final isFull = seconds >= goal;
      final opacity = isFull ? 1.0 : (seconds / goal);
      final override = pieceOverrides[id];
      final subject =
          override?['subject'] as String? ?? (b['subject'] as String);
      final secondsOverride = override?['seconds'] as int? ?? seconds;
      pieces.add({
        'id': id,
        'imagePath': active.imagePath,
        'opacity': opacity,
        'subject': subject,
        'seconds': secondsOverride,
        'index': i,
        'isPartial': !isFull,
      });
    }
    return pieces;
  }

  /// Update per-piece override (subject and/or seconds). Persist and notify.
  Future<void> updatePieceOverride(
    String pieceId, {
    String? subject,
    int? seconds,
  }) async {
    final existing = pieceOverrides[pieceId] ?? {};
    if (subject != null) existing['subject'] = subject;
    if (seconds != null) existing['seconds'] = seconds;
    pieceOverrides[pieceId] = existing;
    await save();
    notifyListeners();
  }

  Future<void> createNotebook({
    required String selectedTheme,
    required String? selectedImagePath,
    String? defaultSubject,
    String? title,
  }) async {
    // Always create a new notebook; in earlier POC code we reused a debug
    // notebook which prevented creating new notebooks when running in
    // debug mode. Remove that behavior so creation is consistent.

    final started = DateTime.now();
    final id = started.millisecondsSinceEpoch.toString();
    final nb = Notebook(
      id: id,
      title: title == null || title.trim().isEmpty
          ? 'わたしのStudy手帳 ♡'
          : title.trim(),
      theme: selectedTheme,
      startedAt: started,
      imagePath: selectedImagePath,
      defaultSubject: defaultSubject,
      note: null,
    );
    notebooks.add(nb);
    activeNotebookId = id;
    // update legacy root fields for compatibility
    theme = selectedTheme;
    imagePath = selectedImagePath;
    notebookStartedAt = started;
    title = nb.title;
    ready = true;
    await save();
    notifyListeners();
  }

  Future<void> selectNotebook(String id) async {
    activeNotebookId = id;
    // update legacy root fields for compatibility
    final nb = activeNotebook;
    if (nb != null) {
      theme = nb.theme;
      imagePath = nb.imagePath;
      notebookStartedAt = nb.startedAt;
      title = nb.title;
      ready = true;
    }
    await save();
    notifyListeners();
  }

  Future<void> updateTitle(String value, {String? notebookId}) async {
    final trimmed = value.trim();
    final newTitle = trimmed.length > 30 ? trimmed.substring(0, 30) : trimmed;
    final targetId = notebookId ?? activeNotebookId;
    if (targetId != null) {
      notebooks = notebooks
          .map(
            (n) => n.id == targetId
                ? Notebook(
                    id: n.id,
                    title: newTitle,
                    theme: n.theme,
                    startedAt: n.startedAt,
                    imagePath: n.imagePath,
                    defaultSubject: n.defaultSubject,
                    note: n.note,
                    completedAt: n.completedAt,
                  )
                : n,
          )
          .toList();
      // if updating active notebook, also sync legacy title
      if (activeNotebookId == targetId) title = newTitle;
    } else {
      title = newTitle;
    }
    await _syncCollectionIfCompleted();
    await save();
    notifyListeners();
  }

  Future<void> updateNotebookNote(String? note, {String? notebookId}) async {
    final targetId = notebookId ?? activeNotebookId;
    if (targetId == null) return;
    notebooks = notebooks
        .map(
          (n) => n.id == targetId
              ? Notebook(
                  id: n.id,
                  title: n.title,
                  theme: n.theme,
                  startedAt: n.startedAt,
                  imagePath: n.imagePath,
                  defaultSubject: n.defaultSubject,
                  note: note,
                  completedAt: n.completedAt,
                )
              : n,
        )
        .toList();
    await save();
    notifyListeners();
  }

  Future<void> addSession({
    required String subject,
    required int seconds,
  }) async {
    if (seconds <= 0) return;
    sessions.add(
      StudySession(
        at: DateTime.now(),
        subject: subject,
        seconds: seconds,
        notebookId: activeNotebookId,
      ),
    );
    await _syncCollectionIfCompleted();
    await save();
    notifyListeners();
  }

  Future<void> _syncCollectionIfCompleted() async {
    final active = activeNotebook;
    if (active == null) return;
    if (!completed) return;
    final id = active.startedAt.millisecondsSinceEpoch.toString();
    final item = CollectionItem(
      id: id,
      title: active.title,
      imagePath: active.imagePath,
      theme: active.theme,
      completedAt: DateTime.now(),
      totalSeconds: notebookSeconds,
      topSubject: topSubject,
    );
    collections.removeWhere((entry) => entry.id == id);
    collections.insert(0, item);
    // Keep the notebook active after completion. Additional study time starts
    // filling the next collection piece while the notebook photo stays fully
    // developed.
  }

  Future<void> updateSubjects(List<String> values) async {
    subjects = values;
    await save();
    notifyListeners();
  }

  Future<void> deleteCollection(String id) async {
    collections.removeWhere((item) => item.id == id);
    await save();
    notifyListeners();
  }

  Future<void> deleteCurrentNotebook() async {
    if (activeNotebookId == null) return;
    await deleteNotebook(activeNotebookId!);
  }

  /// Delete a notebook by id, remove its sessions, collections, and image files.
  Future<void> deleteNotebook(String id) async {
    Notebook? nb;
    try {
      nb = notebooks.firstWhere((n) => n.id == id);
    } catch (_) {
      nb = null;
    }
    if (nb == null) return;
    // collect collection image paths to delete for this notebook id
    final collectionPaths = collections
        .where((c) => c.id == id)
        .map((c) => c.imagePath)
        .whereType<String>()
        .toList();
    // remove notebook and its sessions
    notebooks.removeWhere((n) => n.id == id);
    sessions.removeWhere((s) => s.notebookId == id);
    // remove collection entries for this notebook
    collections.removeWhere((c) => c.id == id);
    // attempt to delete image files (notebook image + any collection images)
    final pathsToDelete = <String>[];
    if (nb.imagePath != null) pathsToDelete.add(nb.imagePath!);
    pathsToDelete.addAll(collectionPaths);
    for (final p in pathsToDelete) {
      try {
        await ImageStorage.delete(p);
      } catch (_) {
        // ignore file deletion errors
      }
    }
    // if we deleted active notebook, clear active state
    if (activeNotebookId == id) {
      activeNotebookId = null;
      ready = false;
      notebookStartedAt = null;
      imagePath = null;
      title = 'わたしのStudy手帳 ♡';
    }
    await save();
    notifyListeners();
  }

  Future<void> reset() async {
    // delete all stored images for notebooks and collections
    for (final n in notebooks) {
      try {
        await ImageStorage.delete(n.imagePath);
      } catch (_) {}
    }
    for (final c in collections) {
      try {
        await ImageStorage.delete(c.imagePath);
      } catch (_) {}
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
    // reset all in-memory state
    ready = false;
    title = 'わたしのStudy手帳 ♡';
    theme = 'heart';
    imagePath = null;
    notebookStartedAt = null;
    subjects = ['英語', '数学', '国語', '理科', '社会'];
    sessions = [];
    collections = [];
    notebooks = [];
    activeNotebookId = null;
    pieceOverrides = {};
    notifyListeners();
  }
}
