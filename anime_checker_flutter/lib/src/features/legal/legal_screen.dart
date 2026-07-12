import 'package:flutter/material.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            document.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            document.updatedAt,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          for (final section in document.sections)
            _LegalSection(section: section),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.section});

  final LegalSection section;

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
              section.title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final body in section.body)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(body),
              ),
          ],
        ),
      ),
    );
  }
}

class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.updatedAt,
    required this.sections,
  });

  final String title;
  final String updatedAt;
  final List<LegalSection> sections;
}

class LegalSection {
  const LegalSection({required this.title, required this.body});

  final String title;
  final List<String> body;
}

const privacyPolicyDocument = LegalDocument(
  title: '개인정보처리방침',
  updatedAt: '시행일: 2026.07.01.',
  sections: [
    LegalSection(
      title: '수집하는 정보',
      body: [
        '애니 체크는 계정, 이름, 연락처, 위치, 사진, 마이크 정보를 수집하지 않습니다.',
        '앱 안에는 사용자가 저장한 보관함, 보류, 찜, 시청 기록, 메모, 백업 시간이 저장될 수 있습니다.',
        '사용자가 피드백 보내기를 이용하면 작성한 내용과 선택 입력한 이메일 주소가 Cloudflare Worker를 통해 개발자에게 전송되어 저장될 수 있습니다.',
        '이 정보는 기본적으로 기기 내부 저장소와 사용자가 직접 내보낸 JSON 백업 파일에 저장됩니다.',
      ],
    ),
    LegalSection(
      title: '네트워크 사용',
      body: [
        '검색, 신작 애니, 애니 소식, 포스터와 원문 링크를 가져오기 위해 Cloudflare Worker 프록시와 외부 데이터 제공자에 요청을 보낼 수 있습니다.',
        'TMDB API 키는 앱에 저장하지 않고 서버 프록시에서만 사용합니다.',
        '피드백은 사용자가 직접 보내기 버튼을 눌렀을 때만 서버로 전송됩니다.',
      ],
    ),
    LegalSection(
      title: '제3자 제공 및 공유',
      body: [
        '앱은 사용자의 시청 기록, 보관함, 찜, 메모를 개발자 서버로 동기화하거나 판매하지 않습니다.',
        '사용자가 백업 파일을 직접 공유하거나 다른 위치에 저장하는 경우 해당 파일 관리는 사용자 책임입니다.',
      ],
    ),
    LegalSection(
      title: '보관 및 삭제',
      body: [
        '앱 데이터는 사용자가 앱 안의 전체 초기화 기능을 실행하거나 앱을 삭제하면 기기에서 제거됩니다.',
        'JSON 백업 파일은 사용자가 저장한 위치에서 직접 삭제해야 합니다.',
      ],
    ),
    LegalSection(
      title: '문의',
      body: ['개인정보와 피드백 문의는 yujy9897@gmail.com 으로 보낼 수 있습니다.'],
    ),
  ],
);

const dataSourceDocument = LegalDocument(
  title: '데이터 출처 및 저작권 고지',
  updatedAt: '시행일: 2026.07.03.',
  sections: [
    LegalSection(
      title: '데이터 제공자',
      body: [
        '신작 애니와 일부 상세 정보는 Jikan API를 통해 제공되는 MyAnimeList 기반 공개 데이터를 사용합니다.',
        '한국어 제목, 포스터, 시즌, 에피소드, 방영일 등의 일부 보강 정보는 TMDB 데이터를 기반으로 표시될 수 있습니다.',
        '애니 소식은 Google 뉴스 RSS, Bing 뉴스 RSS 등 외부 뉴스 검색 결과에서 제목, 요약, 출처, 날짜, 원문 링크를 정리해 보여줍니다.',
      ],
    ),
    LegalSection(
      title: '공식 제휴 아님',
      body: [
        '애니 체크는 TMDB, MyAnimeList, Jikan, Google, Bing, 각 언론사와 공식 제휴하거나 보증받은 앱이 아닙니다.',
        '각 서비스명, 상표, 로고, 작품 정보, 포스터, 기사 정보의 권리는 해당 권리자와 제공자에게 있습니다.',
      ],
    ),
    LegalSection(
      title: '이미지와 기사',
      body: [
        '작품 포스터는 외부 데이터 제공자가 제공하는 이미지 URL을 앱 화면에 표시하는 용도로만 사용합니다.',
        '기사 전문을 앱에 복제하지 않으며 원문 확인은 해당 언론사 또는 원문 페이지에서 이루어집니다.',
        '뉴스 기사 이미지는 저작권과 표시 안정성 문제를 줄이기 위해 앱 카드에 표시하지 않습니다.',
      ],
    ),
    LegalSection(
      title: 'Cloudflare Worker 프록시',
      body: [
        '앱은 API 키 보호와 응답 정리를 위해 Cloudflare Worker 프록시를 사용합니다.',
        'TMDB API 키는 앱에 포함하지 않고 Worker secret으로만 보관합니다.',
        'Worker는 외부 데이터를 앱에서 쓰기 쉬운 형태로 정리하며, 데이터의 원 저작권을 소유하지 않습니다.',
      ],
    ),
    LegalSection(
      title: '사용자 데이터',
      body: [
        '사용자가 저장한 시청 기록, 메모, 찜 목록은 사용자의 개인 기록입니다.',
        '보관함, 보류, 찜, 시청 기록은 기본적으로 기기 내부 저장소와 사용자가 직접 내보낸 백업 파일에 저장됩니다.',
      ],
    ),
  ],
);
