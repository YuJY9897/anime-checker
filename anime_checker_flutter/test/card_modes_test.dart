import 'package:anime_checker_flutter/src/core/theme/theme.dart';
import 'package:anime_checker_flutter/src/widgets/anime_card.dart';
import 'package:anime_checker_flutter/src/widgets/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {double width = 360}) => MaterialApp(
  theme: buildAppTheme(Brightness.dark),
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  // 스크린샷만 보고 "막대가 그려진다"고 판단했다가 틀렸다. Stack에 fit이 없으면
  // 채움 칸이 0 크기로 찌그러져 그라데이션이 아예 안 칠해지는데, 화면에서는
  // 막대 길이가 달라 보여서 동작하는 것처럼 보였다.
  testWidgets('진행률 막대의 채움 칸이 실제로 그려진다', (tester) async {
    await tester.pumpWidget(
      _wrap(const GradientProgressBar(value: 0.5, height: 4)),
    );

    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, 0.5);

    final box = tester.getSize(
      find.descendant(
        of: find.byType(FractionallySizedBox),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(box.height, greaterThan(0), reason: '채움 칸 높이가 0이면 안 보인다');
    expect(box.width, greaterThan(0), reason: '채움 칸 폭이 0이면 안 보인다');
  });

  testWidgets('진행률 0과 1에서도 막대가 터지지 않는다', (tester) async {
    for (final value in [0.0, 1.0]) {
      await tester.pumpWidget(
        _wrap(GradientProgressBar(value: value, height: 3)),
      );
      expect(tester.takeException(), isNull, reason: 'value=$value');
    }
  });

  // 신작 애니만 카드에 listMode를 안 넘겨서, 목록 모드에서 큰 표지 모양이
  // 높이 제한 없는 자리에 놓여 터졌다.
  testWidgets('목록 모드 카드는 높이 제한이 없어도 터지지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                for (var i = 0; i < 3; i += 1)
                  AnimePosterCard(
                    key: ValueKey('a$i'),
                    title: '아주 긴 제목을 가진 작품 $i 이름이 두 줄을 넘어가도 괜찮아야 한다',
                    posterUrl: '',
                    genres: const ['액션/모험', '공상과학/판타지'],
                    metaLines: const ['12/24화 · 50%', '최근 시즌 1 · 12화'],
                    statusLabel: '방영중',
                    listMode: true,
                    progress: 0.5,
                    onTap: () {},
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(AnimePosterCard), findsNWidgets(3));
    expect(find.text('방영중'), findsNWidgets(3));
  });

  testWidgets('모르는 상태는 칩을 띄우지 않는다', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AnimePosterCard(
          title: '작품',
          posterUrl: '',
          statusLabel: '정보 확인 중',
          listMode: true,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('정보 확인 중'), findsNothing);
  });
}
