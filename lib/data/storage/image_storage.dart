import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Stores only a file name in app data and resolves it against the current
/// iOS/Android app container at runtime. App container absolute paths are not
/// stable across every install/update lifecycle.
class ImageStorage {
  ImageStorage._();

  static String? _documentsPath;

  static Future<void> initialize() async {
    _documentsPath ??= (await getApplicationDocumentsDirectory()).path;
  }

  static String resolve(String storedPath) {
    if (storedPath.isEmpty || File(storedPath).isAbsolute) return storedPath;
    final root = _documentsPath;
    return root == null ? storedPath : '$root/$storedPath';
  }

  static Future<String> import(String sourcePath) async {
    await initialize();
    final source = File(sourcePath);
    final extension = _safeExtension(sourcePath);
    final fileName = 'oshi_${DateTime.now().microsecondsSinceEpoch}$extension';
    await source.copy(resolve(fileName));
    return fileName;
  }

  /// Converts legacy absolute paths to a stable file name. During an app
  /// container move, iOS normally migrates Documents to its new location. If
  /// the old file is still reachable, copy it into the current container.
  static Future<String?> migrate(String? storedPath) async {
    if (storedPath == null || storedPath.isEmpty) return storedPath;
    await initialize();
    if (!File(storedPath).isAbsolute) return storedPath;

    final fileName = Uri.file(storedPath).pathSegments.last;
    final currentPath = resolve(fileName);
    final currentFile = File(currentPath);
    if (!await currentFile.exists()) {
      final legacyFile = File(storedPath);
      if (await legacyFile.exists()) {
        await legacyFile.copy(currentPath);
      }
    }
    return fileName;
  }

  static Future<void> delete(String? storedPath) async {
    if (storedPath == null || storedPath.isEmpty) return;
    await initialize();
    final file = File(resolve(storedPath));
    if (await file.exists()) await file.delete();
  }

  static String _safeExtension(String path) {
    final fileName = Uri.file(path).pathSegments.last;
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return '.jpg';
    final extension = fileName.substring(dot).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,5}$').hasMatch(extension)
        ? extension
        : '.jpg';
  }
}
