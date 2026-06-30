import 'package:flutter/material.dart';

import '../news/news_screen.dart';
import '../shell/shell_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'new_anime_screen.dart';
import 'schedule_screen.dart';
import 'wish_screen.dart';

class MainSectionBody extends StatelessWidget {
  const MainSectionBody({super.key, required this.section});

  final MainSection section;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case MainSection.updates:
        return const HomeScreen();
      case MainSection.library:
        return const LibraryScreen(mode: LibraryMode.library);
      case MainSection.dropped:
        return const LibraryScreen(mode: LibraryMode.dropped);
      case MainSection.wish:
        return const WishScreen();
      case MainSection.newAnime:
        return const NewAnimeScreen();
      case MainSection.schedule:
        return const ScheduleScreen();
      case MainSection.news:
        return const NewsScreen();
    }
  }
}
