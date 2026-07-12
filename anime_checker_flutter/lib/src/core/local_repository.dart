import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'sample_data.dart';

class LocalRepository {
  static const _fileName = 'anime_checker_data.json';

  // 웹 미리보기 전용: 파일 시스템 대신 인메모리 저장(영속성 없음).
  AppData? _webCache;

  Future<File> _dataFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<AppData> load() async {
    if (kIsWeb) return _webCache ??= sampleAppData();
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
    if (kIsWeb) {
      _webCache = data;
      return;
    }
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
