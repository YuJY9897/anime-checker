# 피드백 관리

앱의 `환경설정 > 피드백 보내기`에서 전송된 내용은 Cloudflare Worker의 `FEEDBACK_KV`에 저장된다.

## 피드백 목록 보기

```powershell
cd "C:\Users\yjy\Desktop\애니 체크\anime_checker_proxy"
npx wrangler kv key list --remote --namespace-id 7cd4a7b40bf643db9dac197ce2784500 --prefix feedback:
```

## 피드백 내용 보기

```powershell
cd "C:\Users\yjy\Desktop\애니 체크\anime_checker_proxy"
npx wrangler kv key get "feedback:YYYY-MM-DD:KEY" --remote --namespace-id 7cd4a7b40bf643db9dac197ce2784500 --text
```

## 처리한 피드백 삭제

```powershell
cd "C:\Users\yjy\Desktop\애니 체크\anime_checker_proxy"
npx wrangler kv key delete "feedback:YYYY-MM-DD:KEY" --remote --namespace-id 7cd4a7b40bf643db9dac197ce2784500
```

## 저장되는 값

- 문의 종류
- 제목
- 내용
- 답장 받을 이메일(사용자가 입력한 경우)
- 앱 버전
- 사용자 기기에서 보낸 시각
- 서버 저장 시각

사용자가 직접 `보내기`를 누른 피드백만 저장한다.

