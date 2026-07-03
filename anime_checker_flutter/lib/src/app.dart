import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_controller.dart';
import 'core/theme.dart';
import 'features/shell/shell_screen.dart';

class AnimeCheckerApp extends ConsumerWidget {
  const AnimeCheckerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(appControllerProvider).settings.darkMode;
    return MaterialApp(
      title: '애니 체크',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const ShellScreen(),
    );
  }
}
