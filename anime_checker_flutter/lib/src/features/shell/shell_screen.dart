import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../backup/backup_screen.dart';
import '../home/main_sections.dart';
import '../search/search_screen.dart';

enum MainSection { updates, library, dropped, wish, newAnime, schedule, news }

extension MainSectionText on MainSection {
  String get label {
    switch (this) {
      case MainSection.updates:
        return '새 화';
      case MainSection.library:
        return '보관함';
      case MainSection.dropped:
        return '보류';
      case MainSection.wish:
        return '찜';
      case MainSection.newAnime:
        return '신작 애니';
      case MainSection.schedule:
        return '요일 편성표';
      case MainSection.news:
        return '애니 소식';
    }
  }
}

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  MainSection section = MainSection.updates;
  DateTime? lastBackAt;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(appControllerProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleRootBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(section.label),
          actions: [
            IconButton(
              tooltip: '검색',
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
            ),
            IconButton(
              tooltip: '백업',
              icon: const Icon(Icons.save_alt),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const BackupScreen())),
            ),
            PopupMenuButton<MainSection>(
              tooltip: '메뉴',
              icon: const Icon(Icons.menu),
              onSelected: (value) => setState(() => section = value),
              itemBuilder: (context) => MainSection.values
                  .map(
                    (value) =>
                        PopupMenuItem(value: value, child: Text(value.label)),
                  )
                  .toList(),
            ),
          ],
        ),
        body: controller.ready
            ? MainSectionBody(section: section)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _handleRootBack() {
    if (section != MainSection.updates) {
      setState(() => section = MainSection.updates);
      return;
    }
    final now = DateTime.now();
    final canExit =
        lastBackAt != null &&
        now.difference(lastBackAt!) < const Duration(seconds: 2);
    if (canExit) {
      SystemNavigator.pop();
      return;
    }
    lastBackAt = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('한 번 더 누르면 종료됩니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
