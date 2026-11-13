import 'package:flutter/material.dart';

ThemeData buildAppTheme(Brightness brightness) {
  const seed = Color(0xFF275F57);
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  // 바탕은 더 깊게, 카드는 더 띄운다. 예전엔 둘의 명도 차가 6% 남짓인데
  // 다크에서 그림자까지 0이라 모든 것이 한 평면에 붙어 보였다.
  final background = isDark ? const Color(0xFF0B1210) : const Color(0xFFF4F6F5);
  final card = isDark ? const Color(0xFF1A2220) : const Color(0xFFFFFFFF);
  final cardHigh = isDark ? const Color(0xFF232D2A) : const Color(0xFFEFF4F1);
  final cardHighest = isDark
      ? const Color(0xFF2E3A36)
      : const Color(0xFFE4ECE8);
  final ink = isDark ? const Color(0xFFE9F1ED) : const Color(0xFF151C19);
  final muted = isDark ? const Color(0xFF9FB3AB) : const Color(0xFF68736E);
  final outline = isDark ? const Color(0xFF2C3A35) : const Color(0xFFDDE5E0);
  final shadow = isDark ? const Color(0xCC000000) : const Color(0x26000000);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme.copyWith(
      surface: background,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainer: card,
      surfaceContainerHigh: cardHigh,
      surfaceContainerHighest: cardHighest,
      primary: isDark ? const Color(0xFF8FD8C4) : seed,
      onPrimary: isDark ? const Color(0xFF08201A) : Colors.white,
      secondary: isDark ? const Color(0xFFFFB29B) : const Color(0xFFC55F42),
      tertiary: isDark ? const Color(0xFF92D4FF) : const Color(0xFF2F7199),
      outlineVariant: outline,
    ),
    scaffoldBackgroundColor: background,
    fontFamilyFallback: const ['Roboto', 'Noto Sans KR'],
    textTheme: TextTheme(
      // 32px급 제목이 없어 "큰 것"이 없었다. 화면 제목을 여기까지 키운다.
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: ink,
        height: 1.02,
        letterSpacing: -0.9,
      ),
      headlineMedium: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w900,
        color: ink,
        height: 1.1,
        letterSpacing: -0.6,
      ),
      headlineSmall: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w900,
        color: ink,
        height: 1.15,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: ink,
        height: 1.18,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: ink,
        height: 1.22,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: ink,
        height: 1.24,
      ),
      // 본문까지 굵으면 위계가 안 생긴다. 굵기는 제목에만 남긴다.
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ink,
        height: 1.42,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        color: ink,
        fontWeight: FontWeight.w800,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        color: ink,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        color: muted,
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: background,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 68,
      titleTextStyle: TextStyle(
        fontSize: 29,
        fontWeight: FontWeight.w900,
        color: ink,
        height: 1.05,
        letterSpacing: -0.8,
      ),
    ),
    cardTheme: CardThemeData(
      // 다크에서도 그림자를 준다. 카드가 바탕 위에 떠 보이게 하는 핵심.
      elevation: isDark ? 8 : 2,
      color: card,
      margin: EdgeInsets.zero,
      shadowColor: shadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: outline),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: ink,
        backgroundColor: card,
        fixedSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(
          color: isDark ? const Color(0xFF6B827A) : const Color(0xFF789188),
          width: 1.2,
        ),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w700),
      hintStyle: TextStyle(color: muted.withValues(alpha: 0.72)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: card,
      selectedColor: isDark ? const Color(0xFF284A3F) : const Color(0xFFD7EDE2),
      checkmarkColor: scheme.primary,
      side: BorderSide(color: outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      secondaryLabelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: card,
      elevation: isDark ? 0 : 5,
      shadowColor: shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(
        color: ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.primary,
      textColor: ink,
      subtitleTextStyle: TextStyle(color: muted, fontSize: 13),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFFE9F1ED) : ink,
      contentTextStyle: TextStyle(
        color: isDark ? const Color(0xFF101614) : Colors.white,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: DividerThemeData(color: outline),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? scheme.primary : muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary.withValues(alpha: 0.35)
            : outline,
      ),
    ),
  );
}
