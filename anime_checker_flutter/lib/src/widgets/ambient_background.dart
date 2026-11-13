import 'package:flutter/material.dart';

/// 바탕에 아주 옅은 빛 두 덩이를 깔아 화면에 깊이를 준다.
/// 카드 그림자만으로는 단색 바탕 위에서 떠 보이지 않아, 빛이 닿는 면을
/// 만들어 주는 역할. 다크에서만 쓰고, 라이트에서는 그냥 통과시킨다.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness != Brightness.dark) return child;
    final colors = theme.colorScheme;
    return Stack(
      children: [
        Positioned(
          top: -150,
          left: -110,
          child: _Glow(color: colors.primary, size: 360, strength: 0.16),
        ),
        Positioned(
          top: 230,
          right: -140,
          child: _Glow(color: colors.tertiary, size: 320, strength: 0.10),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.color,
    required this.size,
    required this.strength,
  });

  final Color color;
  final double size;
  final double strength;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: strength),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.72],
          ),
        ),
      ),
    );
  }
}
