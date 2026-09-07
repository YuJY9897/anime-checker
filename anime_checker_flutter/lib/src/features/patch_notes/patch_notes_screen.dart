import 'package:flutter/material.dart';

import '../../data/patch_notes.dart';

/// 지난 업데이트 내용을 모아 보여준다.
class PatchNotesScreen extends StatelessWidget {
  const PatchNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('업데이트 내용')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: patchNotes.length,
        itemBuilder: (context, index) {
          final note = patchNotes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _PatchNoteBody(note: note, showLatestBadge: index == 0),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 버전 하나의 내용. 안내 창과 목록 화면이 같은 모양을 쓴다.
class _PatchNoteBody extends StatelessWidget {
  const _PatchNoteBody({required this.note, this.showLatestBadge = false});

  final PatchNote note;
  final bool showLatestBadge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '버전 ${note.version}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            if (showLatestBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '최신',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            const Spacer(),
            Text(
              note.date,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final item in note.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 업데이트 후 처음 열었을 때 한 번 보여주는 안내 창.
Future<void> showPatchNoteDialog(BuildContext context, PatchNote note) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('업데이트했어요'),
      content: SingleChildScrollView(child: _PatchNoteBody(note: note)),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PatchNotesScreen()),
            );
          },
          child: const Text('지난 내용 보기'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}
