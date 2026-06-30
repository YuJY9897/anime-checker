# 애니 체크 Flutter

Android 우선 네이티브 애니 시청 기록 앱입니다. 데이터는 앱 내부 JSON 파일과 JSON 백업/복원으로 관리합니다.

## 실행

```powershell
flutter pub get
flutter run -d <device-id> --dart-define=ANIME_CHECKER_API_BASE=https://your-worker.example.workers.dev
```

Worker 주소를 넣지 않으면 샘플 데이터로 동작합니다. TMDB API 키는 앱에 넣지 않습니다.

## 검증

```powershell
dart analyze --no-fatal-warnings
flutter test
flutter build apk --debug
```

## 구조

- `lib/src/core`: 모델, 로컬 저장, API, Riverpod 컨트롤러, 날짜/테마
- `lib/src/features/shell`: 오른쪽 위 메뉴와 루트 뒤로가기
- `lib/src/features/home`: 새 화, 보관함, 보류, 찜, 신작 애니, 요일 편성표
- `lib/src/features/detail`: 상세, 시즌, 에피소드, 극장판/영화
- `lib/src/features/news`: 애니 소식, 뉴스 상세, 앱 내부 원문 화면
- `lib/src/features/search`: 검색 결과
- `lib/src/features/backup`: JSON 백업/복원
- `lib/src/widgets`: 공통 카드/헤더/빈 상태

## 제외 범위

- 계정/로그인/클라우드 동기화
- 후속 대기 상태
- 최근 본 애니 섹션
- 보기/정보/나무위키 버튼
- 더미 이미지
