# AGENTS.md

## 프로젝트 개요

이 저장소는 `애니 체크` Flutter 앱과 Cloudflare Worker 프록시로 구성된다.

- `anime_checker_flutter/`: Android 우선 네이티브 Flutter 앱
- `anime_checker_proxy/`: TMDB API 키 보호와 Jikan 신작 데이터 정리를 위한 Cloudflare Worker

## 현재 제품 방향

- 메인 화면은 `새 화`다.
- 6개 주요 메뉴는 하단 탭이 아니라 오른쪽 위 `메뉴`에서 선택한다.
- 메뉴 구성:
  - `새 화`
  - `보관함`
  - `보류`
  - `찜`
  - `신작 애니`
  - `요일 편성표`
  - `애니 소식`
- `목록`이라는 이름은 쓰지 않고 `보관함`을 쓴다.
- 애니 카드는 포스터와 카드 전체가 터치 영역이다.
- 버튼은 불필요하게 한 줄 전체를 차지하지 않게 compact하게 둔다.
- 모바일에서 공백, 줄바꿈, overflow를 반드시 확인한다.

## 기능 기준

### 새 화

- 새로 방영됐고 아직 안 본 화가 있는 작품만 표시한다.
- 보류 작품은 제외한다.
- 같은 작품은 중복 표시하지 않는다.
- 오늘 볼 애니에는 화별 목록이 아니라 작품 단위로 표시한다.

### 보관함

- 보는 중이거나 다 봤지만 계속 보관할 작품을 둔다.
- 진행률을 표시한다.
- 카드 액션 버튼은 카드 하단 정렬을 유지한다.

### 보류

- 잠시 멈춘 작품을 둔다.
- 새 화에서는 제외한다.
- 요일 편성표에는 현재 방영중이면 `보류` 라벨로 포함한다.

### 찜

- 보관함에 넣기 전 후보를 둔다.
- 보관함에 추가하면 찜에서 제거한다.

### 신작 애니

- 한국어 제목 중심으로 보여준다.
- 일본 애니가 아닌 항목은 최대한 제외한다.
- 년도 선택과 월 선택으로 월별 개봉작을 볼 수 있게 한다.
- 장르와 방영일/발매일은 같은 줄에 붙이지 않는다.
- 미래 날짜는 `YYYY.MM.DD. 방영예정`으로 표시한다.

### 요일 편성표

- 메인 하단에 넣지 않고 별도 메뉴로 둔다.
- 보관함, 새 화 대상, 보류 작품을 모두 포함한다.
- 완결/종영/취소 작품은 제외하고 현재 방영중 작품만 표시한다.
- 요일 정보가 없으면 최근 에피소드 방영일에서 요일을 추론한다.

### 애니 소식

- 한국 애니 신작, 시즌, 극장판, 흥행/관객 수/순위 중심으로 보여준다.
- 기사 이미지가 있으면 카드에 같이 보여준다.
- 원문 보기는 앱 내부 화면에서 연다.
- 관련 없는 뉴스, 웹툰/게임/굿즈/리뷰성 글은 최대한 제외한다.

### 백업

- 앱 전용 JSON 내보내기/불러오기를 지원한다.
- 보관함, 보류, 찜, 시청 기록을 함께 저장하고 복원한다.
- 복원 전 전체/보류/찜/시청 기록 개수를 보여준다.

## 데이터/API

- Flutter 앱은 로컬 JSON 파일 하나를 원본 데이터로 사용한다.
- 저장 시 임시 파일에 먼저 쓰고 성공하면 원본으로 교체한다.
- 앱에 TMDB API 키를 절대 넣지 않는다.
- TMDB 호출은 Cloudflare Worker를 통해 처리한다.
- 신작 애니 목록은 Jikan 시즌 API를 1차 소스로 쓰고, TMDB 결과는 한국어 제목/보강용으로 병합한다.
- Jikan은 API 키가 필요 없으며, Jikan 상세 ID는 `mal-숫자` 형태로 처리한다.

Worker 엔드포인트:

- `GET /search?q=...`
- `GET /anime/{tmdbId}`
- `GET /anime/mal-{malId}`
- `GET /new-anime?region=KR`
- `GET /news`
- `GET /image?url=...`

Worker secret:

- `TMDB_API_KEY`

## 실행

Flutter 앱:

```powershell
cd anime_checker_flutter
flutter pub get
flutter run -d <device-id> --dart-define=ANIME_CHECKER_API_BASE=https://anime-checker-proxy.duffkaus29.workers.dev
```

Worker:

```powershell
cd anime_checker_proxy
npm install
npx wrangler secret put TMDB_API_KEY
npx wrangler deploy
```

## 검증

코드 수정 후 가능한 검증을 반드시 실행한다.

```powershell
cd anime_checker_flutter
dart format --set-exit-if-changed lib test
dart analyze --no-fatal-warnings
flutter test
flutter build apk --debug --dart-define=ANIME_CHECKER_API_BASE=https://anime-checker-proxy.duffkaus29.workers.dev
```

실기기 확인이 필요한 UI 변경은 ADB로 설치 후 직접 확인한다.

```powershell
adb -s <device-id> install -r build\app\outputs\flutter-apk\app-debug.apk
```

## GitHub에 올리면 안 되는 파일

- `.venv/`
- `venv/`
- `anime_check_data.json`
- `anime_check_data.tmp`
- `__pycache__/`
- `*.pyc`
- `anime_checker_proxy/node_modules/`
- `anime_checker_proxy/.wrangler/`
- `anime_checker_flutter/build/`
- `anime_checker_flutter/.dart_tool/`
- `anime_checker_flutter/.flutter-plugins`
- `anime_checker_flutter/.flutter-plugins-dependencies`

## 작업 원칙

- 기능별 파일 분리를 유지한다.
- UI는 직접 저장소나 API를 호출하지 않고 Provider/Controller를 거친다.
- 다른 메뉴를 고치다가 기존 메뉴가 깨지지 않게 변경 범위를 좁힌다.
- 수정 후에는 실제 화면에서 버튼, overflow, 뒤로가기 흐름을 확인한다.
- 사용자가 배포, 공개, 앱스토어 출시를 언급하면 AI 규제/개인정보/저작권/보안 체크리스트도 같이 점검한다.


