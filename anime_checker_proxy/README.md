# 애니 체크 Proxy

Flutter 앱에서 TMDB API 키를 직접 들고 가지 않도록 하는 Cloudflare Worker입니다.

## 설정

```powershell
npm install
npx wrangler secret put TMDB_API_KEY
npx wrangler deploy
```

## 엔드포인트

- `GET /search?q=...`
- `GET /anime/{tmdbId}`
- `GET /new-anime?region=KR`
- `GET /news`
- `GET /image?url=...`

Flutter 앱에는 배포된 Worker 주소만 전달합니다.

```powershell
flutter run --dart-define=ANIME_CHECKER_API_BASE=https://your-worker.example.workers.dev
```
