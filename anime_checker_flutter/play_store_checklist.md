# 애니 체크 Play Store 등록 체크리스트

최종 확인일: 2026.07.03.

## 빌드/서명

- 패키지 이름: `com.yjy.anime_checker_flutter`
- 앱 이름: `애니 체크`
- 현재 앱 버전: `1.0.0+1`
- Flutter 3.44.4 기본값 기준 `targetSdkVersion 36`, `compileSdkVersion 36`, `minSdkVersion 24`
- release AAB는 `android/key.properties`의 업로드 키로 서명한다.
- `android/key.properties`, `*.jks`, `*.keystore`, `build/`, `.dart_tool/`은 Git에 올리지 않는다.
- Play Console 업로드 파일: `build/app/outputs/bundle/release/app-release.aab`

## Play Console 입력

- 앱 카테고리: 도구 또는 엔터테인먼트 중 선택
- 광고 포함 여부: 광고 없음
- 앱 액세스: 로그인 없이 사용 가능
- 타겟층: 성인/일반 사용자 기준. 어린이 대상 앱으로 등록하지 않음
- 콘텐츠 등급: 사용자 제작 콘텐츠 없음, 폭력/성적 콘텐츠 직접 제공 없음 기준으로 설문 작성
- 개인정보처리방침 URL: `privacy_policy.html` 내용을 공개 URL에 올린 뒤 입력
- 데이터 출처 및 저작권 고지: `data_sources_and_copyright.html` 내용을 앱 설명 또는 지원 페이지에 함께 공개
- 데이터 보안: 로컬 시청 기록/찜/메모는 기기 내부 저장, 피드백 작성 시 사용자가 입력한 내용과 선택 이메일이 서버로 전송될 수 있음

## 정책/저작권

- TMDB 데이터를 사용하지만 TMDB 공식/인증 앱이 아니라고 고지한다.
- Jikan/MAL 기반 데이터와 외부 뉴스 제목/요약/링크는 출처 성격을 명확히 한다.
- 기사 전문과 기사 이미지를 앱 안에 임의로 복제하지 않는다.
- 앱 설명에 “개인 시청 기록 관리용 앱”이라고 명확히 쓴다.

## 출시 전 수동 확인

- 개발자 계정 본인 인증과 주소 증빙 완료
- 새 개인 개발자 계정이면 Google Play의 테스트 요구사항 확인
- 개인정보처리방침 공개 URL 접속 확인
- 스토어 등록정보: 아이콘, 기능 그래픽, 휴대전화 스크린샷, 짧은 설명, 긴 설명 입력
- 내부 테스트 트랙에 AAB 업로드 후 Play Console 사전 검토 경고 확인
- Cloudflare Worker 배포 상태와 `TMDB_API_KEY` secret 설정 확인
