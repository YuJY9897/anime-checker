import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../backup/backup_screen.dart';
import '../legal/legal_screen.dart';
import 'feedback_screen.dart';
import 'help_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final settings = controller.settings;
    return ListView(
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
            const SizedBox(height: 10),
            _DropdownRow<String>(
              label: '보관함 정렬',
              value: settings.librarySort,
              items: const {
                'title': '제목순',
                'recentAirDate': '최근 방영일순',
                'lowProgress': '진행 낮은순',
                'highProgress': '진행 높은순',
                'completedFirst': '완료 먼저',
              },
              onChanged: (value) => controller.updateSettings(
                settings.copyWith(librarySort: value),
              ),
            ),
          ],
        ),
        _SettingsGroup(
          title: '요일 편성표 설정',
          children: [
            _SwitchRow(
              title: '보류 작품 포함',
              value: settings.includeDroppedInSchedule,
              onChanged: (value) => controller.updateSettings(
                settings.copyWith(includeDroppedInSchedule: value),
              ),
            ),
            _SwitchRow(
              title: '요일 자동 추론',
              value: settings.inferScheduleWeekday,
              onChanged: (value) => controller.updateSettings(
                settings.copyWith(inferScheduleWeekday: value),
              ),
            ),
          ],
        ),
        _SettingsGroup(
          title: '애니 소식 설정',
          children: [
            _SwitchRow(
              title: '기사 이미지 표시',
              value: settings.showNewsImages,
              onChanged: (value) => controller.updateSettings(
                settings.copyWith(showNewsImages: value),
              ),
            ),
            _SwitchRow(
              title: '원문을 앱 안에서 열기',
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
            const _StaticRow(label: '앱 버전', value: '1.0.0+1'),
            const SizedBox(height: 8),
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
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const FeedbackScreen())),
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
    );
  }

  void _openLegal(BuildContext context, LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalDocumentScreen(document: document),
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

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentValue = items.containsKey(value) ? value : items.keys.first;
    return DropdownButtonFormField<T>(
      initialValue: currentValue,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items: items.entries
          .map(
            (entry) =>
                DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
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
