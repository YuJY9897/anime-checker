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
                metaLines: const ['방영일: 2026.07.01. 방영예정'],
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

  testWidgets('compact anime grid uses shorter card height', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<double> rowGap({required bool compact}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TwoColumnAnimeGrid(
              compact: compact,
              children: List.generate(
                4,
                (index) => AnimePosterCard(
                  title: '테스트 $index',
                  posterUrl: '',
                  genres: const ['액션'],
                  metaLines: const ['방영일: 2026.07.01. 방영예정'],
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

    final normalGap = await rowGap(compact: false);
    final compactGap = await rowGap(compact: true);

    expect(compactGap, lessThan(normalGap));
  });
}
