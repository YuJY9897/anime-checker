import 'package:anime_checker_flutter/src/data/local/local_repository.dart';
import 'package:anime_checker_flutter/src/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repo = LocalRepository();

  test('정상 백업은 그대로 복원된다', () {
    final source = AppData.empty().copyWith(
      watchedEpisodes: {'100:s1:e1': true},
      animeNotes: {'100': '메모'},
    );

    final restored = repo.parseBackup(source.toPrettyJson());

    expect(restored.watchedEpisodes['100:s1:e1'], isTrue);
    expect(restored.animeNotes['100'], '메모');
  });

  test('JSON이 아니면 형식 오류를 알린다', () {
    expect(() => repo.parseBackup('그냥 텍스트'), throwsFormatException);
  });

  test('다른 앱의 JSON은 거부한다', () {
    expect(() => repo.parseBackup('{"foo": 1}'), throwsFormatException);
  });

  test('JSON 배열은 거부한다', () {
    expect(() => repo.parseBackup('[1, 2, 3]'), throwsFormatException);
  });
}
