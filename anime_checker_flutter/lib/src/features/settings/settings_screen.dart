import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../state/app_controller.dart';
import '../../core/format/date_text.dart';
import '../../widgets/scroll_top_area.dart';
import '../backup/backup_screen.dart';
import '../legal/legal_screen.dart';
import '../patch_notes/patch_notes_screen.dart';
import 'feedback_screen.dart';
import 'help_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final settings = controller.settings;
    return ScrollTopArea(
      builder: (scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SettingsGroup(
            title: '데이터 관리',
            children: [
              _InfoRow(
                label: '마지막 백업',
                value: controller.data.lastBackupAt == null
                    ? '아직 없음'
                    : formatDotDate(
                        controller.data.lastBackupAt!,
                        withTime: true,
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save_alt),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BackupScreen()),
                      ),
                      label: const Text('백업 / 복원'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      onPressed: () => _confirmReset(context, controller),
                      label: const Text('전체 초기화'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (controller.refreshingAll)
                _RefreshAllProgress(controller: controller)
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cloud_download_outlined),
                    onPressed: controller.apiConfigured
                        ? () => _confirmRefreshAll(context, controller)
                        : null,
                    label: const Text('모든 작품 정보 다시 받기'),
                  ),
                ),
            ],
          ),
          _SettingsGroup(
            title: '표시 설정',
            children: [
              _SwitchRow(
                title: '카드 이미지 표시',
                value: settings.showPosterImages,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(showPosterImages: value),
                ),
              ),
              _SwitchRow(
                title: '다크 모드',
                value: settings.darkMode,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(darkMode: value),
                ),
              ),
              _SwitchRow(
                title: '뉴스 이미지 표시',
                value: settings.showNewsImages,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(showNewsImages: value),
                ),
              ),
              _SwitchRow(
                title: '뉴스 원문을 앱 안에서 열기',
                value: settings.openNewsInsideApp,
                onChanged: (value) => controller.updateSettings(
                  settings.copyWith(openNewsInsideApp: value),
                ),
              ),
            ],
          ),
          _SettingsGroup(
            title: '앱 정보',
            children: [
              const _AppVersionRow(),
              const SizedBox(height: 8),
              _OpenRow(
                icon: Icons.new_releases_outlined,
                title: '업데이트 내용',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PatchNotesScreen()),
                ),
              ),
              _OpenRow(
                icon: Icons.menu_book_outlined,
                title: '설명서',
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const HelpScreen())),
              ),
              _OpenRow(
                icon: Icons.feedback_outlined,
                title: '피드백 보내기',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                ),
              ),
              _OpenRow(
                icon: Icons.privacy_tip_outlined,
                title: '개인정보처리방침',
                onTap: () => _openLegal(context, privacyPolicyDocument),
              ),
              _OpenRow(
                icon: Icons.source_outlined,
                title: '데이터 출처 및 저작권',
                onTap: () => _openLegal(context, dataSourceDocument),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openLegal(BuildContext context, LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalDocumentScreen(document: document),
      ),
    );
  }

  void _confirmRefreshAll(BuildContext context, AppController controller) {
    final count = controller.allAnime.length;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 작품 정보를 다시 받을까요?'),
        content: Text(
          '보관함 $count개 작품의 시즌과 회차를 처음부터 다시 받아요. '
          '기수가 하나로 묶여 있던 작품은 이때 나뉘고, 시청 기록은 새 회차로 옮겨져요. '
          '몇 분 걸릴 수 있어요. 걱정되면 먼저 백업해 두세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              controller.refreshAllAnimeDetails();
            },
            child: const Text('다시 받기'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, AppController controller) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 초기화할까요?'),
        content: const Text('보관함, 보류, 찜, 시청 기록을 모두 비웁니다. 설정은 유지됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              controller.resetAllData();
            },
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AppVersionRow extends StatelessWidget {
  const _AppVersionRow();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return _StaticRow(
          label: '앱 버전',
          value: info == null ? '-' : '${info.version}+${info.buildNumber}',
        );
      },
    );
  }
}

class _StaticRow extends StatelessWidget {
  const _StaticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: _InfoRow(label: label, value: value),
    );
  }
}

class _OpenRow extends StatelessWidget {
  const _OpenRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _RefreshAllProgress extends StatelessWidget {
  const _RefreshAllProgress({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final total = controller.refreshAllTotal;
    final done = controller.refreshAllDone;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '정보 다시 받는 중  $done / $total',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: controller.cancelRefreshAll,
              child: const Text('중단'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total == 0 ? null : done / total,
            minHeight: 8,
            backgroundColor: colors.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
