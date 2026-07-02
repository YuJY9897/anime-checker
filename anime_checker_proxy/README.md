# 애니 체크 Proxy

Flutter 앱에서 외부 API를 직접 다루지 않도록 하는 Cloudflare Worker입니다.

- TMDB API 키는 Worker secret으로만 보관합니다.
- 신작 애니 목록은 Jikan 시즌 API를 1차 소스로 사용합니다.
- 검색과 TMDB 상세/한국어 보강은 TMDB를 사용합니다.
- Jikan `mal-...` ID 상세도 `/anime/{id}`에서 처리합니다.

## 설정

```powershell
npm install
npx wrangler secret put TMDB_API_KEY
npx wrangler deploy
```

Jikan은 API 키가 필요 없습니다.

## 엔드포인트

- `GET /search?q=...`
- `GET /anime/{tmdbId}`
- `GET /anime/mal-{malId}`
- `GET /new-anime?region=KR`
- `GET /news`
- `GET /image?url=...`

Flutter 앱에는 배포된 Worker 주소만 전달합니다.

```powershell
flutter run --dart-define=ANIME_CHECKER_API_BASE=https://your-worker.example.workers.dev
```
