import 'package:flutter/material.dart';

ThemeData buildAppTheme(Brightness brightness) {
  const seed = Color(0xFF275F57);
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  final background = isDark ? const Color(0xFF101614) : const Color(0xFFF4F6F5);
  final card = isDark ? const Color(0xFF17211E) : const Color(0xFFFFFFFF);
  final cardHigh = isDark ? const Color(0xFF22302B) : const Color(0xFFEFF4F1);
  final cardHighest = isDark
      ? const Color(0xFF2B3C35)
      : const Color(0xFFE4ECE8);
  final ink = isDark ? const Color(0xFFE9F1ED) : const Color(0xFF151C19);
  final muted = isDark ? const Color(0xFFB8C7C0) : const Color(0xFF68736E);
  final outline = isDark ? const Color(0xFF3B4C45) : const Color(0xFFDDE5E0);
  final shadow = isDark ? Colors.black54 : const Color(0x26000000);

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
      headlineSmall: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w900,
        color: ink,
        height: 1.15,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: ink,
        height: 1.18,
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
      bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.38),
      bodySmall: TextStyle(fontSize: 13, color: muted, height: 1.34),
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
      toolbarHeight: 60,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: ink,
        height: 1.1,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: isDark ? 0 : 1,
      color: card,
      margin: EdgeInsets.zero,
      shadowColor: shadow,
      surfaceTintColor: card,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: outline),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: ink,
        backgroundColor: card,
        fixedSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
