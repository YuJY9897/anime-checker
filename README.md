# 애니 체크

[![Google Play](https://img.shields.io/badge/Google%20Play-출시-414141?logo=googleplay&logoColor=white)](https://play.google.com/store/apps/details?id=com.yjy.anime_checker_flutter)
[![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Cloudflare Workers](https://img.shields.io/badge/Cloudflare-Workers-F38020?logo=cloudflare&logoColor=white)](https://workers.cloudflare.com)

> **보는 OTT를 자주 옮기다 보니 어떤 작품을 어디까지 봤는지 기억나지 않는 일이 잦았습니다.** 시청 기록이 플랫폼마다 따로 남기 때문입니다.
> 그래서 OTT와 관계없이 한 곳에 기록을 모아두는 앱을 만들었고, 이후 소식과 신작 정보를 더했습니다.

Android 우선 Flutter 애니 시청 기록 앱입니다. 현재 저장소는 Flutter 앱과 Cloudflare Worker 프록시를 기준으로 관리합니다.

**👉 [Google Play에서 설치하기](https://play.google.com/store/apps/details?id=com.yjy.anime_checker_flutter)**

## 직접 해결한 것

- **스토어 심사 요구사항을 혼자 처리했습니다** — 개인정보처리방침 작성·게시, 데이터 안전 섹션 신고, 타겟 API 레벨 대응
- **API 키를 앱에 넣지 않았습니다** — TMDB 키는 Cloudflare Worker secret으로 두고 앱은 프록시만 호출하도록 분리해, 디컴파일해도 키가 나오지 않습니다
- **배포를 스크립트로 자동화했습니다** — 버전을 올릴 때마다 반복되던 빌드·업로드·심사 제출을 명령 한 번으로 처리합니다
- 코드는 AI 도구를 활용해 작성했고, 붙여넣고 끝내지 않고 전체 구동 흐름이 그려질 때까지 확인한 뒤 넘어갔습니다

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
