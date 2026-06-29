import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'sample_data.dart';

class LocalRepository {
  static const _fileName = 'anime_checker_data.json';

  Future<File> _dataFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<AppData> load() async {
    final file = await _dataFile();
    if (!await file.exists()) {
      final data = sampleAppData();
      await save(data);
      return data;
    }
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return AppData.empty();
    return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(AppData data) async {
    final file = await _dataFile();
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(data.toPrettyJson(), flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await temp.rename(file.path);
  }

  Future<File> exportBackup(AppData data) async {
    final dir = await getApplicationDocumentsDirectory();
    final name =
        'anime-checker-backup-${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.writeAsString(
      data.copyWith(lastBackupAt: DateTime.now()).toPrettyJson(),
      flush: true,
    );
    return file;
  }

  AppData parseBackup(String raw) =>
      AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
