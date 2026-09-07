import 'package:anime_checker_flutter/src/data/patch_notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('처음 켠 사용자에게는 최신 내용을 보여준다', () {
    final note = patchNoteToShow('');

    expect(note, isNotNull);
    expect(note!.version, patchNotes.first.version);
  });

  test('최신 버전을 이미 봤으면 다시 보여주지 않는다', () {
    expect(patchNoteToShow(patchNotes.first.version), isNull);
  });

  test('예전 버전만 본 사용자에게는 최신 내용을 보여준다', () {
    expect(patchNoteToShow('1.0.2')?.version, patchNotes.first.version);
  });

  test('목록은 최신 버전이 맨 앞에 온다', () {
    int weight(String v) {
      final parts = v.split('.').map(int.parse).toList();
      return parts[0] * 10000 + parts[1] * 100 + parts[2];
    }

    for (var i = 0; i < patchNotes.length - 1; i++) {
      expect(
        weight(patchNotes[i].version),
        greaterThan(weight(patchNotes[i + 1].version)),
        reason: '${patchNotes[i].version}가 ${patchNotes[i + 1].version}보다 뒤에 있음',
      );
    }
  });

  test('모든 항목에 날짜와 내용이 채워져 있다', () {
    for (final note in patchNotes) {
      expect(note.date.trim(), isNotEmpty, reason: '${note.version} 날짜 없음');
      expect(note.items, isNotEmpty, reason: '${note.version} 내용 없음');
      for (final item in note.items) {
        expect(item.trim(), isNotEmpty);
      }
    }
  });
}
