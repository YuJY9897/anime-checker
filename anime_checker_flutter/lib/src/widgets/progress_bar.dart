import 'package:flutter/material.dart';

/// 진행률 막대. 단색 대신 옅은 민트에서 진한 민트로 번지게 해
/// 카드 안에서 한 군데라도 빛이 도는 지점을 만든다.
class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({super.key, required this.value, this.height = 4});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ratio = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: Stack(
          // fit이 없으면 채움 칸(DecoratedBox)이 자식 없는 0 크기로 찌그러져
          // 그라데이션이 아예 안 칠해지고, Stack 폭까지 그 칸에 맞춰 줄어든다.
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ColoredBox(color: colors.surfaceContainerHighest),
            ),
            FractionallySizedBox(
              widthFactor: ratio,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(colors.primary, colors.surface, 0.34) ??
                          colors.primary,
                      colors.primary,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
