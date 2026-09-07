// 버전별 변경 내용. 최신 버전이 목록 맨 앞에 온다.
//
// 새 버전을 낼 때 여기 맨 위에 한 항목을 추가하면
// 업데이트 후 앱을 처음 열 때 한 번 안내되고, 환경설정에서 언제든 다시 볼 수 있다.
class PatchNote {
  const PatchNote({
    required this.version,
    required this.date,
    required this.items,
  });

  final String version;
  final String date;
  final List<String> items;
}

const patchNotes = <PatchNote>[
  PatchNote(
    version: '1.0.9',
    date: '2026.09.04',
    items: [
      '업데이트 내용을 앱에서 바로 볼 수 있게 했어요. 환경설정에서 지난 내용도 확인할 수 있어요.',
      '잘 쓰이지 않던 도움말 챗봇을 없앴어요. 사용법은 설명서에서 확인해 주세요.',
    ],
  ),
  PatchNote(
    version: '1.0.8',
    date: '2026.09.04',
    items: [
      '여러 기수가 하나로 묶여 있던 작품을 기수별로 나눠서 보여줍니다.',
      '기수가 나뉘어도 이미 체크한 시청 기록은 그대로 유지됩니다.',
      "환경설정에 '모든 작품 정보 다시 받기'를 추가했습니다.",
    ],
  ),
  PatchNote(
    version: '1.0.7',
    date: '2026.09.04',
    items: [
      '시청 통계 화면을 추가했습니다. 지금까지 본 화수와 장르를 한눈에 볼 수 있어요.',
      '애니 소식 목록에 기사 이미지가 함께 나옵니다.',
      '앱을 켰을 때 첫 화면이 더 빨리 나오도록 개선했습니다.',
      '백업 파일을 잘못 선택하면 이유를 알려줍니다.',
      '목록을 불러오지 못했을 때 다시 시도할 수 있습니다.',
    ],
  ),
  PatchNote(
    version: '1.0.5',
    date: '2026.08.27',
    items: [
      '앱 아이콘을 새로 단장했습니다.',
      '방영 중인 작품의 새 화를 자동으로 받아옵니다.',
      '회차 제목을 목록에서 바로 볼 수 있습니다.',
      '아직 방영하지 않은 화는 시청 처리되지 않도록 막았습니다.',
      '설정 화면의 앱 버전이 실제 버전으로 표시됩니다.',
    ],
  ),
  PatchNote(
    version: '1.0.2',
    date: '2026.08.11',
    items: [
      '애니 체크 첫 정식 출시입니다.',
      '보관함으로 시청 화수를 관리하고, 신작 애니를 분기별로 탐색할 수 있어요.',
      '요일 편성표와 애니 소식도 확인해 보세요.',
    ],
  ),
];

/// 업데이트 후 처음 열었을 때 안내할 내용. 보여줄 게 없으면 null.
///
/// [lastSeenVersion]은 사용자가 마지막으로 확인한 버전이다.
/// 비어 있으면(처음 켜거나 이 기능이 생기기 전 사용자) 최신 내용을 한 번 보여준다.
PatchNote? patchNoteToShow(String lastSeenVersion) {
  if (patchNotes.isEmpty) return null;
  final latest = patchNotes.first;
  return lastSeenVersion == latest.version ? null : latest;
}
