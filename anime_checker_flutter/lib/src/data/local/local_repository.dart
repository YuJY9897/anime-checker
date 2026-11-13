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

  /// 저장이 겹치면 같은 임시 파일을 두고 다투다 rename이 실패한다.
  /// 들어온 순서대로 하나씩 쓴다.
  Future<void> _queue = Future<void>.value();

  Future<void> save(AppData data) {
    if (kIsWeb) {
      _webCache = data;
      return Future<void>.value();
    }
    final next = _queue.then((_) => _write(data));
    // 한 번 실패해도 다음 저장까지 막히지 않게 체인에서는 오류를 흘린다.
    _queue = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<void> _write(AppData data) async {
    final file = await _dataFile();
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(data.toPrettyJson(), flush: true);
    try {
      // 안드로이드(POSIX)에서는 같은 폴더 덮어쓰기 rename이 원자적이다.
      // 예전처럼 원본을 먼저 지우면 그 틈에 앱이 죽었을 때 파일이 없는 채로
      // 남고, 다음 실행에서 load()가 샘플 데이터를 그대로 저장해 버린다.
      await temp.rename(file.path);
    } on FileSystemException {
      // 윈도우는 덮어쓰기 rename을 막는다(테스트 환경에서만 지나간다).
      if (await file.exists()) await file.delete();
      await temp.rename(file.path);
    }
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
