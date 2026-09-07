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
    icon: Icons.insights_outlined,
    title: '시청 통계',
    body:
        '지금까지 본 화수와 시간, 보관함 대비 진행률을 보여줍니다. 완주·보는 중·시작 전·보류·찜 개수와 많이 본 장르, 가장 많이 본 작품도 함께 확인할 수 있습니다.',
  ),
  _HelpItem(
    icon: Icons.backup_outlined,
    title: '백업 / 복원',
    body:
        '보관함, 보류, 찜, 시청 기록을 JSON 파일로 내보내거나 다시 불러옵니다. 애니 체크 백업이 아닌 파일을 고르면 이유를 알려주고 기존 데이터는 그대로 둡니다.',
  ),
  _HelpItem(
    icon: Icons.layers_outlined,
    title: '기수 나누기',
    body:
        '여러 기수가 한 시즌으로 묶여 있는 작품은 기수별로 나누어 보여줍니다. 나뉘어도 이미 체크한 시청 기록은 해당 기수의 회차로 그대로 옮겨집니다.',
  ),
  _HelpItem(
    icon: Icons.cloud_download_outlined,
    title: '모든 작품 정보 다시 받기',
    body:
        '환경설정에서 보관함 전체의 시즌과 회차를 처음부터 다시 받습니다. 완결작은 자동 갱신 대상이 아니라서, 기수가 묶여 있던 작품을 나누려면 한 번 실행해 주세요. 진행 중 중단할 수 있습니다.',
  ),
  _HelpItem(
    icon: Icons.new_releases_outlined,
    title: '업데이트 내용',
    body:
        '앱이 업데이트되면 처음 열 때 바뀐 내용을 한 번 안내합니다. 환경설정 → 업데이트 내용에서 지난 버전 기록도 버전을 눌러 펼쳐 볼 수 있습니다.',
  ),
];
