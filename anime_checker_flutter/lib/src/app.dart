import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/shell/shell_screen.dart';

class AnimeCheckerApp extends StatelessWidget {
  const AnimeCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '애니 체크',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const ShellScreen(),
    );
  }
}
