import 'package:anime_checker_flutter/src/widgets/anime_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('anime grid keeps two columns on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TwoColumnAnimeGrid(
            children: List.generate(
              4,
              (index) => AnimePosterCard(
                title: '애니 $index',
                posterUrl: '',
                genres: const ['액션'],
                metaLines: const ['방영일: 2026.07.01.', '방영예정'],
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final first = tester.getTopLeft(find.text('애니 0'));
    final second = tester.getTopLeft(find.text('애니 1'));
    final third = tester.getTopLeft(find.text('애니 2'));

    expect(second.dx, greaterThan(first.dx));
    expect((third.dy - first.dy).abs(), greaterThan(20));
  });

  testWidgets('card height follows content amount', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<double> rowGap({required List<String> metaLines}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TwoColumnAnimeGrid(
              children: List.generate(
                4,
                (index) => AnimePosterCard(
                  title: '테스트 $index',
                  posterUrl: '',
                  genres: const ['액션'],
                  metaLines: metaLines,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      final first = tester.getTopLeft(find.text('테스트 0'));
      final third = tester.getTopLeft(find.text('테스트 2'));
      return third.dy - first.dy;
    }

    final shortGap = await rowGap(metaLines: const ['방영일: 2026.07.01.']);
    final tallGap = await rowGap(metaLines: const ['방영일: 2026.07.01.', '방영예정']);

    expect(tallGap, greaterThan(shortGap));
  });

  testWidgets('compact anime card fits text and actions without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TwoColumnAnimeGrid(
            children: List.generate(
              4,
              (index) => AnimePosterCard(
                title: '자동판매기로 다시 태어난 나는 미궁을 방랑한다 $index',
                posterUrl: '',
                genres: const ['Action & Adventure', 'Sci-Fi & Fantasy', '코미디'],
                metaLines: const ['다음 3기 12화', '방영일: 2026.06.17.'],
                actions: [
                  AnimeCardAction(label: '추가', onPressed: () {}),
                  AnimeCardAction(label: '찜', onPressed: () {}),
                ],
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
