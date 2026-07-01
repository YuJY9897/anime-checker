import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../home/main_sections.dart';
import '../search/search_screen.dart';

enum MainSection {
  updates,
  library,
  dropped,
  wish,
  newAnime,
  schedule,
  news,
  settings,
}

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
      case MainSection.settings:
        return '환경설정';
    }
  }

  IconData get icon {
    switch (this) {
      case MainSection.updates:
        return Icons.playlist_play_outlined;
      case MainSection.library:
        return Icons.inventory_2_outlined;
      case MainSection.dropped:
        return Icons.pause_circle_outline;
      case MainSection.wish:
        return Icons.star_border_rounded;
      case MainSection.newAnime:
        return Icons.auto_awesome_outlined;
      case MainSection.schedule:
        return Icons.calendar_month_outlined;
      case MainSection.news:
        return Icons.article_outlined;
      case MainSection.settings:
        return Icons.tune_outlined;
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
              tooltip: '메뉴',
              icon: const Icon(Icons.menu),
              onPressed: _openSectionMenu,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: controller.ready
            ? MainSectionBody(section: section)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _openSectionMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  '메뉴',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              );
            }
            final value = MainSection.values[index - 1];
            final selected = value == section;
            return ListTile(
              leading: Icon(selected ? Icons.check_circle : value.icon),
              title: Text(value.label),
              selected: selected,
              onTap: () {
                Navigator.pop(context);
                setState(() => section = value);
              },
            );
          },
          separatorBuilder: (_, index) =>
              index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
          itemCount: MainSection.values.length + 1,
        ),
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
