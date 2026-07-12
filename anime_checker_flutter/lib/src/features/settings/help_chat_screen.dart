import 'package:flutter/material.dart';

/// 오프라인 도움말 챗봇.
/// 설명서/개인정보처리방침/데이터 출처 내용을 키워드 매칭으로 답변한다.
/// 외부 API 호출 없이 기기 안에서만 동작한다.
class HelpChatScreen extends StatefulWidget {
  const HelpChatScreen({super.key});

  @override
  State<HelpChatScreen> createState() => _HelpChatScreenState();
}

class _HelpChatScreenState extends State<HelpChatScreen> {
  final textController = TextEditingController();
  final scrollController = ScrollController();
  final messages = <_ChatMessage>[
    const _ChatMessage(
      text: '안녕하세요, 애니 체크 도우미예요.\n앱 사용법이나 개인정보, 데이터 출처가 궁금하면 편하게 물어보세요.',
      fromUser: false,
    ),
  ];

  static const suggestions = [
    '새 화가 뭐예요?',
    '시청 체크는 어떻게 해요?',
    '백업은 어떻게 해요?',
    '개인정보를 수집하나요?',
    '데이터는 어디서 가져오나요?',
    '뒤로가기는 어떻게 동작해요?',
  ];

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _send(String input) {
    final question = input.trim();
    if (question.isEmpty) return;
    setState(() {
      messages.add(_ChatMessage(text: question, fromUser: true));
      messages.add(_ChatMessage(text: _answerFor(question), fromUser: false));
    });
    textController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('도움말 챗봇')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  _ChatBubble(message: messages[index]),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) => ActionChip(
                label: Text(suggestions[index]),
                labelStyle: Theme.of(context).textTheme.labelMedium,
                visualDensity: VisualDensity.compact,
                onPressed: () => _send(suggestions[index]),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: '궁금한 점을 입력하세요',
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: '보내기',
                    style: IconButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                    ),
                    onPressed: () => _send(textController.text),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _answerFor(String question) {
    final normalized = question.toLowerCase();
    _ChatTopic? best;
    var bestScore = 0;
    for (final topic in _topics) {
      var score = 0;
      for (final keyword in topic.keywords) {
        if (normalized.contains(keyword)) score += keyword.length;
      }
      if (score > bestScore) {
        bestScore = score;
        best = topic;
      }
    }
    if (best == null) {
      return '아직 그 질문은 답변을 준비하지 못했어요.\n'
          '이런 주제를 물어볼 수 있어요:\n'
          '· 새 화 / 보관함 / 보류 / 찜\n'
          '· 신작 애니 / 요일 편성표 / 애니 소식\n'
          '· 시청 체크 / 검색과 추가 / 백업과 복원\n'
          '· 다크 모드 / 뒤로가기 / 전체 초기화\n'
          '· 개인정보 / 데이터 출처와 저작권 / 피드백';
    }
    return best.answer;
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fromUser = message.fromUser;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: fromUser ? colors.primary : colors.surfaceContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(fromUser ? 14 : 4),
            bottomRight: Radius.circular(fromUser ? 4 : 14),
          ),
          border: fromUser ? null : Border.all(color: colors.outlineVariant),
        ),
        child: Text(
          message.text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: fromUser ? colors.onPrimary : colors.onSurface,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ChatTopic {
  const _ChatTopic({required this.keywords, required this.answer});

  final List<String> keywords;
  final String answer;
}

const _topics = [
  _ChatTopic(
    keywords: ['새 화', '새화', '이어볼', '안 본 화', '못 본'],
    answer:
        '새 화는 보관함 작품 중 아직 보지 않은 첫 회차를 작품별로 보여주는 기본 화면이에요.\n'
        '오래된 작품도 안 본 화가 있으면 표시되고, 보류 작품과 아직 방영 전인 회차는 제외돼요.\n'
        '카드를 누르면 상세 화면으로 이동해서 바로 시청 체크를 할 수 있어요.',
  ),
  _ChatTopic(
    keywords: ['보관함', '진행률', '정렬'],
    answer:
        '보관함은 보는 중이거나 다 봤지만 계속 보관할 작품을 모아두는 곳이에요.\n'
        '카드에서 진행률(예: 10/24화 · 42%)과 진행 바를 확인할 수 있어요.\n'
        '정렬은 보관함 상단 칩이나 환경설정 → 보관함 정렬에서 바꿀 수 있어요.',
  ),
  _ChatTopic(
    keywords: ['보류', '멈춘', '복귀', '쉬었다'],
    answer:
        '보류는 잠시 멈춘 작품을 따로 두는 곳이에요.\n'
        '보류 중에는 새 화 목록에서 빠지고, 방영 중이라면 요일 편성표에는 보류 라벨로 남아요.\n'
        '카드의 복귀 버튼을 누르면 다시 보관함과 새 화 대상으로 돌아와요.',
  ),
  _ChatTopic(
    keywords: ['찜', '나중에 볼', '후보'],
    answer:
        '찜은 보관함에 넣기 전에 후보를 담아두는 목록이에요.\n'
        '신작 애니나 검색 결과에서 찜 버튼으로 담고, 카드를 누르면 상세 정보를 볼 수 있어요.\n'
        '추가 버튼으로 보관함에 넣으면 찜에서는 자동으로 빠져요.',
  ),
  _ChatTopic(
    keywords: ['신작', '월별', '개봉', '방영예정', '방영 예정', '분기'],
    answer:
        '신작 애니에서는 년도와 월을 골라 그 시기에 나온(나올) 애니를 볼 수 있어요.\n'
        '방영일 아래에 방영중/완결/방영예정 상태가 표시되고, 추가나 찜으로 바로 담을 수 있어요.\n'
        '목록이 안 보이면 오른쪽 위 새로고침을 눌러 다시 불러올 수 있어요.',
  ),
  _ChatTopic(
    keywords: ['편성표', '요일'],
    answer:
        '요일 편성표는 현재 방영 중인 보관함/보류 작품을 요일별로 보여줘요.\n'
        '완결되거나 종영된 작품은 나오지 않고, 요일 정보가 없으면 최근 방영일로 요일을 추론해요.',
  ),
  _ChatTopic(
    keywords: ['소식', '뉴스', '기사', '원문'],
    answer:
        '애니 소식에서는 신작, 시즌, 극장판, 흥행 관련 뉴스를 모아 볼 수 있어요.\n'
        '카드를 누르면 요약을 보고, 원문 보기를 누르면 앱 안에서 기사 원문 페이지가 열려요.\n'
        '상단 칩으로 전체/신작/시즌/극장판/흥행을 걸러볼 수 있어요.',
  ),
  _ChatTopic(
    keywords: ['검색', '추가', '등록'],
    answer:
        '오른쪽 위 돋보기로 애니 제목을 검색할 수 있어요.\n'
        '검색 결과나 신작 애니 카드에서 추가를 누르면 보관함에 들어가고, 시즌/에피소드 정보도 자동으로 가져와요.',
  ),
  _ChatTopic(
    keywords: ['시청', '완료', '에피소드', '회차', '체크', '봤어'],
    answer:
        '상세 화면에서 시즌을 누르면 에피소드 목록이 나와요.\n'
        '시청 버튼을 누르면 그 화까지 이전 화가 모두 완료 처리되고, 완료를 다시 누르면 그 화부터 이후 화가 미완료로 바뀌어요.\n'
        '보관함에 없는 작품도 시청을 누르면 보관함에 추가할지 물어봐요.',
  ),
  _ChatTopic(
    keywords: ['백업', '복원', 'json', '내보내', '불러오', '폰 바꾸', '기기 변경'],
    answer:
        '환경설정 → 백업 / 복원에서 보관함, 보류, 찜, 시청 기록, 메모, 설정을 JSON 파일로 내보낼 수 있어요.\n'
        '폰을 바꾸면 새 폰에서 JSON 불러오기로 복원하면 돼요.\n'
        '복원 전에 파일 안의 작품/찜/시청 기록 개수를 먼저 보여줘요.',
  ),
  _ChatTopic(
    keywords: ['초기화', '리셋', '전부 삭제', '지우'],
    answer:
        '환경설정 → 전체 초기화를 누르면 보관함, 보류, 찜, 시청 기록이 모두 비워져요(설정은 유지).\n'
        '실수 방지를 위해 확인 창이 한 번 더 떠요. 초기화 전에 백업을 만들어 두는 걸 추천해요.',
  ),
  _ChatTopic(
    keywords: ['다크', '테마', '이미지 끄', '포스터 끄', '이미지 표시'],
    answer:
        '환경설정 → 표시 설정에서 다크 모드를 켜고 끌 수 있어요.\n'
        '카드 이미지 표시를 끄면 포스터 없이 정보만 담은 컴팩트한 카드로 바뀌어요.',
  ),
  _ChatTopic(
    keywords: ['뒤로', '종료', '나가'],
    answer:
        '상세나 에피소드 같은 하위 화면에서 뒤로가기를 누르면 이전 화면으로 돌아가요.\n'
        '메뉴 화면에서는 뒤로가기를 누르면 새 화로 이동하고, 새 화에서 두 번 연속 누르면 앱이 종료돼요.',
  ),
  _ChatTopic(
    keywords: ['개인정보', '수집', '계정', '로그인', '프라이버시'],
    answer:
        '애니 체크는 계정, 이름, 연락처, 위치 같은 개인정보를 수집하지 않고 로그인도 필요 없어요.\n'
        '보관함, 시청 기록, 메모는 기본적으로 폰 내부에만 저장돼요.\n'
        '피드백을 보낼 때만 작성한 내용과 선택 입력한 이메일이 서버로 전송돼요.\n'
        '자세한 내용은 환경설정 → 개인정보처리방침에서 볼 수 있어요.',
  ),
  _ChatTopic(
    keywords: ['출처', '저작권', 'tmdb', 'jikan', 'mal', '어디서 가져'],
    answer:
        '신작 애니는 Jikan API(MyAnimeList 공개 데이터)를 기본으로 쓰고, 한국어 제목/포스터/상세는 TMDB 데이터로 보강해요.\n'
        '애니 소식은 Google/Bing 뉴스 RSS의 제목, 요약, 원문 링크를 정리해 보여줘요.\n'
        '애니 체크는 이들 서비스와 공식 제휴한 앱이 아니고, 포스터와 기사 권리는 원 제공자에게 있어요.\n'
        '자세한 내용은 환경설정 → 데이터 출처 및 저작권에서 볼 수 있어요.',
  ),
  _ChatTopic(
    keywords: ['피드백', '문의', '버그', '오류', '건의', '이메일', '개발자'],
    answer:
        '환경설정 → 피드백 보내기에서 기능 제안이나 오류 신고를 앱 안에서 바로 보낼 수 있어요.\n'
        '이메일로 직접 문의하려면 yujy9897@gmail.com 으로 보내면 돼요.',
  ),
  _ChatTopic(
    keywords: ['안녕', '하이', '헬로', '반가'],
    answer: '안녕하세요! 애니 체크 사용법이 궁금하면 아래 추천 질문을 누르거나 편하게 물어보세요.',
  ),
];
