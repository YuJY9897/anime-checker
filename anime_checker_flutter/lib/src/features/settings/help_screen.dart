import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설명서')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemBuilder: (context, index) {
          final item = _helpItems[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Icon(item.icon),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(item.body),
            ),
          );
        },
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemCount: _helpItems.length,
      ),
    );
  }
}

class _HelpItem {
  const _HelpItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

const _helpItems = [
  _HelpItem(
    icon: Icons.playlist_play_outlined,
    title: '새 화',
    body:
        '보관함 작품 중 아직 보지 않은 첫 회차를 작품별로 보여줍니다. 오래된 작품도 안 본 화가 있으면 표시되고, 보류 작품과 아직 방영 전인 회차는 제외됩니다.',
  ),
  _HelpItem(
    icon: Icons.inventory_2_outlined,
    title: '보관함',
    body: '보는 중이거나 다 봤지만 계속 보관할 작품을 모아두는 곳입니다. 진행률과 시청 상태를 확인합니다.',
  ),
  _HelpItem(
    icon: Icons.pause_circle_outline,
    title: '보류',
    body: '잠시 멈춘 작품을 따로 보관합니다. 복귀하면 다시 보관함과 새 화 확인 대상에 포함됩니다.',
  ),
  _HelpItem(
    icon: Icons.star_border_rounded,
    title: '찜',
    body: '나중에 볼 후보를 담아두는 곳입니다. 추가하면 찜에서는 자동으로 빠지고 보관함으로 이동합니다.',
  ),
  _HelpItem(
    icon: Icons.auto_awesome_outlined,
    title: '신작 애니',
    body:
        '년도와 월을 골라 한국어 제목 중심의 신작 애니를 확인합니다. 방영일과 방영중/완결/방영예정 상태를 줄로 나누어 보여주며, 마음에 드는 작품은 찜에 넣거나 바로 추가할 수 있습니다.',
  ),
  _HelpItem(
    icon: Icons.calendar_month_outlined,
    title: '요일 편성표',
    body: '현재 방영 중인 보관함과 보류 작품을 요일별로 확인합니다. 요일 정보가 없으면 최근 방영일로 추론합니다.',
  ),
  _HelpItem(
    icon: Icons.article_outlined,
    title: '애니 소식',
    body: '신작, 시즌, 극장판, 흥행 관련 소식을 확인합니다. 원문은 앱 내부 화면에서 열 수 있습니다.',
  ),
  _HelpItem(
    icon: Icons.backup_outlined,
    title: '백업 / 복원',
    body: '보관함, 보류, 찜, 시청 기록을 JSON 파일로 내보내거나 다시 불러옵니다.',
  ),
];
