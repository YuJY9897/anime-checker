import 'package:flutter/material.dart';

ThemeData buildAppTheme(Brightness brightness) {
  // 색은 Astryx matcha 테마(palette.config.json)의 팔레트 값을 차용했다.
  const seed = Color(0xFF2E6B5A);
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  // 바탕은 더 깊게, 카드는 더 띄운다. 예전엔 둘의 명도 차가 6% 남짓인데
  // 다크에서 그림자까지 0이라 모든 것이 한 평면에 붙어 보였다.
  final background = isDark ? const Color(0xFF12140E) : const Color(0xFFF0F0E0);
  final card = isDark ? const Color(0xFF1A1C14) : const Color(0xFFFFFFFF);
  final cardHigh = isDark ? const Color(0xFF1E2016) : const Color(0xFFDCE3CE);
  final cardHighest = isDark
      ? const Color(0xFF3E481D)
      : const Color(0xFFC0CBA9);
  final ink = isDark ? const Color(0xFFF0F0E0) : const Color(0xFF1A1C14);
  final muted = isDark ? const Color(0xFF94A468) : const Color(0xFF5A6B2A);
  final outline = isDark ? const Color(0xFF3E481D) : const Color(0xFFDCE3CE);
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
      primary: isDark ? const Color(0xFF5AB898) : seed,
      onPrimary: isDark ? const Color(0xFF12140E) : Colors.white,
      secondary: isDark ? const Color(0xFFE0A04A) : const Color(0xFFA06018),
      tertiary: isDark ? const Color(0xFF8DBCE0) : const Color(0xFF2E4A6E),
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
        borderRadius: const BorderRadius.all(Radius.circular(42)),
        side: BorderSide(color: outline),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: ink,
        backgroundColor: card,
        fixedSize: const Size(44, 44),
        shape: const StadiumBorder(),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(
          color: isDark ? const Color(0xFF5A6440) : const Color(0xFF707E46),
          width: 1.2,
        ),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w700),
      hintStyle: TextStyle(color: muted.withValues(alpha: 0.72)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: card,
      selectedColor: isDark ? const Color(0xFF3E481D) : const Color(0xFFDCE3CE),
      checkmarkColor: scheme.primary,
      side: BorderSide(color: outline),
      shape: const StadiumBorder(),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: card,
      elevation: isDark ? 0 : 5,
      shadowColor: shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: isDark ? const Color(0xFFF0F0E0) : ink,
      contentTextStyle: TextStyle(
        color: isDark ? const Color(0xFF12140E) : Colors.white,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primary.withValues(alpha: 0.18),
      indicatorShape: const StadiumBorder(),
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected) ? scheme.primary : muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: states.contains(WidgetState.selected) ? ink : muted,
        ),
      ),
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
