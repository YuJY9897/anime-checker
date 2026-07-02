# 애니 체크

Android 우선 Flutter 애니 시청 기록 앱입니다. 현재 저장소는 Flutter 앱과 Cloudflare Worker 프록시를 기준으로 관리합니다.

## 구성

- `anime_checker_flutter/`: Flutter 앱
- `anime_checker_proxy/`: TMDB 키 보호와 Jikan 신작 데이터 정리를 담당하는 Cloudflare Worker

## 주요 기능

- 새 화 확인
- 보관함, 보류, 찜 관리
- 작품 상세, 시즌, 에피소드 시청 처리
- 극장판/영화 시청 처리
- 신작 애니 월별 탐색
- 요일 편성표
- 애니 소식과 앱 내부 원문 보기
- JSON 백업/복원

## 실행

```powershell
cd anime_checker_flutter
flutter pub get
flutter run -d <device-id> --dart-define=ANIME_CHECKER_API_BASE=https://anime-checker-proxy.duffkaus29.workers.dev
```

Worker 주소를 넣지 않으면 앱은 샘플 데이터 중심으로 동작합니다. TMDB API 키는 앱에 넣지 않고 Cloudflare Worker secret으로 관리합니다. Jikan은 API 키 없이 Worker에서 신작 애니 목록을 가져오는 용도로 사용합니다.

## Worker 배포

```powershell
cd anime_checker_proxy
npm install
npx wrangler secret put TMDB_API_KEY
npx wrangler deploy
```

## 검증

```powershell
cd anime_checker_flutter
dart format --set-exit-if-changed lib test
dart analyze --no-fatal-warnings
flutter test
flutter build apk --debug --dart-define=ANIME_CHECKER_API_BASE=https://anime-checker-proxy.duffkaus29.workers.dev
```

## 민감 정보

- TMDB API 키는 Flutter 앱이나 GitHub에 넣지 않습니다.
- Cloudflare Worker secret `TMDB_API_KEY`로만 관리합니다.
- Jikan은 별도 API 키가 필요 없습니다.
- 로컬 앱 데이터와 백업 파일은 커밋하지 않습니다.
