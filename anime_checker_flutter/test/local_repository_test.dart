import 'dart:convert';
import 'dart:io';

import 'package:anime_checker_flutter/src/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:anime_checker_flutter/src/data/local/local_repository.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.dir);

  final String dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('anime_repo_test');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  File dataFile() => File('${temp.path}${Platform.pathSeparator}'
      'anime_checker_data.json');

  AppData oneAnime() {
    const anime = Anime(
      id: '777',
      title: '테스트 작품',
      originalTitle: '',
      posterUrl: '',
      genres: ['드라마'],
      status: 'Returning Series',
      weekday: '금요일',
      firstAirDate: '2026-11-01',
      seasons: [],
      movies: [],
      dropped: false,
    );
    return AppData.empty().copyWith(
      animeList: {anime.id: anime},
      watchedEpisodes: {'777:s1:e1': true},
    );
  }

  test('저장한 내용을 그대로 다시 읽는다', () async {
    final repo = LocalRepository();
    await repo.save(oneAnime());

    final loaded = await repo.load();
    expect(loaded.animeList.keys, ['777']);
    expect(loaded.watchedEpisodes['777:s1:e1'], isTrue);
  });

  // 예전에는 저장할 때 원본을 먼저 지우고 임시 파일을 rename 했다. 그 사이에
  // 앱이 죽으면 파일이 사라진 상태가 남고, 다음 실행에서 load()가 샘플
  // 데이터를 그대로 저장해 보관함이 샘플 작품으로 바뀌었다.
  test('저장 도중에 끊겨도 이전 내용이 남아 있다', () async {
    final repo = LocalRepository();
    await repo.save(oneAnime());

    // 저장이 시작되기 직전까지 간 상태를 흉내 낸다: 임시 파일만 존재.
    final temp0 = File('${dataFile().path}.tmp');
    await temp0.writeAsString('{"animeList": {}}', flush: true);

    // 이 시점에 원본이 사라져 있으면 안 된다.
    expect(
      await dataFile().exists(),
      isTrue,
      reason: '임시 파일을 쓰는 동안 원본을 지우면 안 된다',
    );

    final loaded = await repo.load();
    expect(loaded.animeList.keys, ['777'], reason: '샘플로 덮이면 안 된다');
  });

  test('비어 있는 파일은 샘플로 덮지 않고 빈 데이터로 읽는다', () async {
    await dataFile().writeAsString('   ', flush: true);

    final loaded = await LocalRepository().load();
    expect(loaded.animeList, isEmpty);
  });

  test('저장을 여러 번 겹쳐도 파일이 깨지지 않는다', () async {
    final repo = LocalRepository();
    await Future.wait([
      repo.save(oneAnime()),
      repo.save(oneAnime()),
      repo.save(oneAnime()),
    ]);

    final raw = await dataFile().readAsString();
    expect(() => jsonDecode(raw), returnsNormally);
    expect((await repo.load()).animeList.keys, ['777']);
  });
}
