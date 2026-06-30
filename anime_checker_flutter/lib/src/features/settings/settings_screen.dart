import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../backup/backup_screen.dart';

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
            FilledButton.icon(
              icon: const Icon(Icons.save_alt),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const BackupScreen())),
              label: const Text('백업 / 복원 열기'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmReset(context, controller),
              label: const Text('전체 초기화'),
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
          title: '새 화 설정',
          children: [
            _SegmentRow<int>(
              label: '새 화 기준',
              value: settings.newEpisodeWindowDays,
              items: const {0: '오늘만', 7: '7일', 14: '14일'},
              onChanged: (value) => controller.updateSettings(
                settings.copyWith(newEpisodeWindowDays: value),
              ),
            ),
            const SizedBox(height: 8),
            const _StaticRow(label: '보류 작품 숨김', value: '항상 켜짐'),
          ],
        ),
        _SettingsGroup(
          title: '신작 애니 설정',
          children: [
            Row(
              children: [
                Expanded(
                  child: _DropdownRow<int>(
                    label: '기본 년도',
                    value: settings.newAnimeDefaultYear,
                    items: _yearItems(),
                    onChanged: (value) => controller.updateSettings(
                      settings.copyWith(newAnimeDefaultYear: value),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DropdownRow<int>(
                    label: '기본 월',
                    value: settings.newAnimeDefaultMonth,
                    items: const {
                      0: '전체',
                      1: '1월',
                      2: '2월',
                      3: '3월',
                      4: '4월',
                      5: '5월',
                      6: '6월',
                      7: '7월',
                      8: '8월',
                      9: '9월',
                      10: '10월',
                      11: '11월',
                      12: '12월',
                    },
                    onChanged: (value) => controller.updateSettings(
                      settings.copyWith(newAnimeDefaultMonth: value),
                    ),
                  ),
                ),
              ],
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
            const _StaticRow(label: '방영 종료 숨김', value: '항상 켜짐'),
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
            const SizedBox(height: 8),
            Text(
              '뉴스 주제',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  const {
                    'newRelease': '신작',
                    'season': '시즌',
                    'movie': '극장판',
                    'boxOffice': '흥행/순위',
                  }.entries.map((entry) {
                    final selected = settings.newsFilters[entry.key] ?? true;
                    return FilterChip(
                      label: Text(entry.value),
                      selected: selected,
                      onSelected: (value) {
                        final filters = Map<String, bool>.from(
                          settings.newsFilters,
                        )..[entry.key] = value;
                        controller.updateSettings(
                          settings.copyWith(newsFilters: filters),
                        );
                      },
                    );
                  }).toList(),
            ),
          ],
        ),
        _SettingsGroup(
          title: '앱 정보',
          children: [
            const _StaticRow(label: '앱 버전', value: '1.0.0+1'),
            _StaticRow(
              label: 'API 서버',
              value: AnimeApiClient.baseUrl.trim().isEmpty
                  ? '샘플 데이터 모드'
                  : AnimeApiClient.baseUrl,
            ),
            const _StaticRow(label: 'API 키', value: '앱에 저장하지 않음'),
          ],
        ),
      ],
    );
  }

  Map<int, String> _yearItems() {
    final now = DateTime.now().year;
    return {
      for (var year = now + 1; year >= now - 3; year -= 1) year: '$year년',
    };
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
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
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

class _SegmentRow<T> extends StatelessWidget {
  const _SegmentRow({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SegmentedButton<T>(
          segments: items.entries
              .map(
                (entry) => ButtonSegment<T>(
                  value: entry.key,
                  label: Text(entry.value),
                ),
              )
              .toList(),
          selected: {value},
          onSelectionChanged: (values) => onChanged(values.first),
        ),
      ],
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
            style: const TextStyle(fontWeight: FontWeight.w800),
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
