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
        '사용자가 피드백 보내기를 이용하면 메일 앱을 통해 이메일 주소와 작성한 내용이 개발자에게 전달될 수 있습니다.',
        '이 정보는 기본적으로 기기 내부 저장소와 사용자가 직접 내보낸 JSON 백업 파일에 저장됩니다.',
      ],
    ),
    LegalSection(
      title: '네트워크 사용',
      body: [
        '검색, 신작 애니, 애니 소식, 포스터와 기사 이미지를 가져오기 위해 Cloudflare Worker 프록시와 외부 데이터 제공자에 요청을 보낼 수 있습니다.',
        'TMDB API 키는 앱에 저장하지 않고 서버 프록시에서만 사용합니다.',
        '피드백 메일은 사용자가 직접 전송 버튼을 눌렀을 때만 메일 앱으로 작성됩니다.',
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
  updatedAt: '시행일: 2026.07.01.',
  sections: [
    LegalSection(
      title: 'TMDB',
      body: [
        '이 앱은 TMDB API를 사용하지만 TMDB가 보증하거나 인증한 앱이 아닙니다.',
        '작품 제목, 포스터, 시즌, 에피소드, 방영일 등의 일부 정보는 TMDB 데이터를 기반으로 표시될 수 있습니다.',
        'TMDB 상표, 로고, 데이터 사용 조건은 TMDB 정책을 따릅니다.',
      ],
    ),
    LegalSection(
      title: '뉴스와 기사',
      body: [
        '애니 소식은 외부 뉴스 출처의 제목, 요약, 출처, 날짜, 원문 링크를 보여줍니다.',
        '기사 전문을 앱에 복제하지 않으며 원문 확인은 해당 언론사 또는 원문 페이지에서 이루어집니다.',
        '기사 이미지가 표시되는 경우에도 해당 이미지의 권리는 원 저작권자에게 있습니다.',
      ],
    ),
    LegalSection(
      title: '사용자 데이터',
      body: [
        '사용자가 저장한 시청 기록, 메모, 찜 목록은 사용자의 개인 기록입니다.',
        '공개 배포 시 앱 설명과 개인정보처리방침에 이 저장 방식을 명확히 표시해야 합니다.',
      ],
    ),
  ],
);

const playStoreChecklistDocument = LegalDocument(
  title: 'Play 출시 전 점검',
  updatedAt: '검토일: 2026.07.01.',
  sections: [
    LegalSection(
      title: '필수 등록 항목',
      body: [
        'Play Console의 Data safety 항목은 실제 저장/전송/공유 동작과 일치해야 합니다.',
        '개인정보처리방침 URL은 공개 접근 가능한 주소로 등록해야 합니다.',
        '앱 콘텐츠 등급 설문과 타겟층을 실제 앱 성격에 맞게 작성해야 합니다.',
      ],
    ),
    LegalSection(
      title: 'Android 빌드',
      body: [
        'Play 제출용 파일은 debug APK가 아니라 release AAB로 만들어야 합니다.',
        '업로드 키는 android/key.properties와 keystore 파일로 로컬에서만 관리하고 GitHub에 올리지 않습니다.',
        '현재 Manifest 권한은 INTERNET만 필요합니다. 불필요한 민감 권한을 추가하지 않습니다.',
      ],
    ),
    LegalSection(
      title: 'AI 및 정책',
      body: [
        '현재 앱은 생성형 AI 기능이나 자동 의사결정 기능을 제공하지 않습니다.',
        '향후 AI 추천, AI 요약, AI 챗봇 기능을 넣는 경우 AI 사용 고지, 부정확 가능성, 처리 데이터 범위를 별도로 표시해야 합니다.',
      ],
    ),
    LegalSection(
      title: '저작권',
      body: [
        '포스터, 작품 정보, 뉴스 이미지, 기사 요약은 각 제공자의 정책을 따릅니다.',
        '기사 전문 복제, 무단 이미지 저장, TMDB 출처 미표기는 출시 심사와 저작권 측면에서 위험합니다.',
      ],
    ),
  ],
);
