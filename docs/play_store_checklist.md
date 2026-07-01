# 애니 체크 Play Store 출시 체크리스트

검토일: 2026.07.01.

## Play Console

- 개인정보처리방침 URL 등록
- Data safety 항목 작성
- 앱 콘텐츠 등급 설문 작성
- 타겟층 및 가족 정책 해당 여부 확인
- 앱 이름, 설명, 스크린샷, 아이콘, 기능 그래픽 준비
- 테스트 트랙에서 실제 설치 확인

## Data safety 초안

- 계정 생성: 없음
- 사용자 식별 정보 수집: 없음
- 위치/연락처/사진/마이크/카메라 권한: 없음
- 앱 내부 저장: 보관함, 보류, 찜, 시청 기록, 메모
- 데이터 공유: 사용자 기록은 공유하지 않음
- 네트워크 요청: Cloudflare Worker, TMDB 데이터, 뉴스 원문/이미지
- 사용자가 데이터 삭제 가능: 앱 안 전체 초기화, 앱 삭제

## Android 빌드

- Play 제출은 debug APK가 아니라 release AAB로 진행
- 업로드 키와 `key.properties`는 GitHub에 올리지 않음
- `.gitignore`에 keystore와 key.properties 제외 포함
- `AndroidManifest.xml` 권한은 현재 `INTERNET`만 사용
- 출시 전 `flutter build appbundle --release` 실행

## 저작권 및 출처

- TMDB 출처 고지 유지
- TMDB가 앱을 보증하거나 인증하지 않는다는 문구 유지
- 기사 전문 복제 금지
- 뉴스 이미지 사용 방식 재검토
- 원문 보기 동작 확인

## AI/규제 체크

- 현재 앱은 생성형 AI 기능을 제공하지 않음
- AI 추천, AI 요약, 챗봇을 추가할 경우 AI 사용 고지와 부정확 가능성 표시 필요
- 사용자의 시청 기록을 AI 처리에 쓰는 경우 별도 동의와 개인정보처리방침 수정 필요
