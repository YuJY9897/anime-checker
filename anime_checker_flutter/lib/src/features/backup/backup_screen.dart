import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../../core/models.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final last = controller.data.lastBackupAt;
    final needsBackup =
        last == null ||
        DateTime.now().difference(last) > const Duration(days: 14);
    return Scaffold(
      appBar: AppBar(title: const Text('백업')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '마지막 백업',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    last == null
                        ? '아직 백업하지 않았어요'
                        : formatDotDate(last, withTime: true),
                  ),
                  if (needsBackup) ...[
                    const SizedBox(height: 8),
                    Text(
                      '오래 백업하지 않았어요. JSON 백업을 저장해 두는 걸 권장합니다.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.ios_share),
            onPressed: () => controller.shareBackup(),
            label: const Text('JSON 내보내기'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.file_open),
            onPressed: () async {
              final backup = await controller.pickBackup();
              if (backup != null && context.mounted) {
                _confirmRestore(context, controller, backup);
              }
            },
            label: const Text('JSON 불러오기'),
          ),
          const SizedBox(height: 18),
          _Summary(controller: controller),
        ],
      ),
    );
  }

  void _confirmRestore(
    BuildContext context,
    AppController controller,
    AppData backup,
  ) {
    final summary = controller.summarize(backup);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('복원할까요?'),
        content: Text(
          '전체 ${summary.total}개, 보류 ${summary.dropped}개, 찜 ${summary.wish}개, 시청 기록 ${summary.watched}개를 불러옵니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              controller.restoreBackup(backup);
            },
            child: const Text('복원'),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summarize(controller.data);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 데이터',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text('전체 ${summary.total}개'),
            Text('보류 ${summary.dropped}개'),
            Text('찜 ${summary.wish}개'),
            Text('시청 기록 ${summary.watched}개'),
          ],
        ),
      ),
    );
  }
}
