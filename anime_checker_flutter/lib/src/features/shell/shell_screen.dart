import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_controller.dart';
import '../../widgets/ambient_background.dart';
import '../home/main_sections.dart';
import '../patch_notes/patch_notes_screen.dart';
import '../search/search_screen.dart';

enum MainSection {
  updates,
  library,
  dropped,
  wish,
  newAnime,
  schedule,
  news,
  stats,
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
      case MainSection.stats:
        return '시청 통계';
      case MainSection.settings:
        return '환경설정';
    }
  }

  /// 하단 탭 칸은 좁아서 긴 이름이 잘린다. 탭에서만 쓰는 짧은 이름.
  String get shortLabel => this == MainSection.schedule ? '편성표' : label;

  /// 탭에서 고른 칸은 속이 찬 아이콘으로 바꿔 지금 어디인지 또렷하게 한다.
  IconData get shortIcon {
    switch (this) {
      case MainSection.updates:
        return Icons.playlist_play;
      case MainSection.library:
        return Icons.inventory_2;
      case MainSection.wish:
        return Icons.star_rounded;
      case MainSection.schedule:
        return Icons.calendar_month;
      default:
        return icon;
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
      case MainSection.stats:
        return Icons.insights_outlined;
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
  /// 하단 탭에 꺼내 두는 넷. 매일 여는 것만 둔다.
  /// 나머지는 마지막 칸 「더보기」에서 고른다.
  static const tabs = [
    MainSection.updates,
    MainSection.library,
    MainSection.wish,
    MainSection.schedule,
  ];

  MainSection section = MainSection.updates;
  DateTime? lastBackAt;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final controller = ref.read(appControllerProvider);
      await controller.load();
      if (mounted) await _showPatchNoteOnce(controller);
    });
  }

  /// 업데이트 후 처음 열었을 때만 안내 창을 띄운다.
  Future<void> _showPatchNoteOnce(AppController controller) async {
    final note = controller.pendingPatchNote;
    if (note == null || !mounted) return;
    await showPatchNoteDialog(context, note);
    await controller.markPatchNoteSeen(note.version);
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
            const SizedBox(width: 8),
          ],
        ),
        body: AmbientBackground(
          child: controller.ready
              ? MainSectionBody(section: section)
              : const Center(child: CircularProgressIndicator()),
        ),
        bottomNavigationBar: NavigationBar(
          // 탭에 없는 화면(보류·신작·소식·통계·환경설정)을 보고 있으면
          // 마지막 칸을 켜 둬서, 지금 어디인지 모르게 되는 것을 막는다.
          selectedIndex: tabs.contains(section)
              ? tabs.indexOf(section)
              : tabs.length,
          onDestinationSelected: (index) {
            if (index == tabs.length) {
              _openSectionMenu();
              return;
            }
            setState(() => section = tabs[index]);
          },
          destinations: [
            for (final tab in tabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.shortIcon),
                label: tab.shortLabel,
              ),
            const NavigationDestination(
              icon: Icon(Icons.more_horiz),
              label: '더보기',
            ),
          ],
        ),
      ),
    );
  }

  void _openSectionMenu() {
    // 탭에 이미 나와 있는 넷은 빼고, 나머지만 보여준다.
    final rest = MainSection.values
        .where((value) => !tabs.contains(value))
        .toList();
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
                  '더보기',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              );
            }
            final value = rest[index - 1];
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
          itemCount: rest.length + 1,
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
