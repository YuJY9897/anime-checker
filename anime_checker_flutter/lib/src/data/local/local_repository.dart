import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';
import '../sample/sample_data.dart';

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

  /// 백업 JSON을 읽는다. 형식이 다르면 FormatException을 던진다.
  AppData parseBackup(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const FormatException('JSON 형식이 아닙니다.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('백업 파일 형식이 아닙니다.');
    }
    // 애니 체크 백업이라면 최소한 이 항목들 중 하나는 들어 있다.
    const markers = ['animeList', 'watchedEpisodes', 'wishList'];
    if (!markers.any(decoded.containsKey)) {
      throw const FormatException('애니 체크 백업 파일이 아닙니다.');
    }
    try {
      return AppData.fromJson(decoded);
    } catch (_) {
      throw const FormatException('백업 내용을 읽을 수 없습니다.');
    }
  }
}
