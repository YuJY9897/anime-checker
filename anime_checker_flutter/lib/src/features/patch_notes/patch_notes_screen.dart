import 'package:flutter/material.dart';

import '../../data/patch_notes.dart';

/// 지난 업데이트 내용을 버전별로 접어서 보여준다. 누르면 그 버전 내용이 펼쳐진다.
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
            padding: const EdgeInsets.only(bottom: 10),
            child: _PatchNoteTile(note: note, isLatest: index == 0),
          );
        },
      ),
    );
  }
}

class _PatchNoteTile extends StatelessWidget {
  const _PatchNoteTile({required this.note, required this.isLatest});

  final PatchNote note;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // 펼침 목록 기본 구분선을 없애 카드 테두리와 겹치지 않게 한다.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Row(
            children: [
              Text(
                '버전 ${note.version}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (isLatest) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              note.date,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          children: [PatchNoteItems(note: note)],
        ),
      ),
    );
  }
}

/// 버전 하나의 변경 내용 목록. 안내 창과 목록 화면이 같은 모양을 쓴다.
class PatchNoteItems extends StatelessWidget {
  const PatchNoteItems({super.key, required this.note});

  final PatchNote note;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '버전 ${note.version} · ${note.date}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            PatchNoteItems(note: note),
          ],
        ),
      ),
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
