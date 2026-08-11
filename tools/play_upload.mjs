// Play Developer API로 AAB를 업로드하고 지정한 트랙에 제출한다.
// 사용법: node tools/play_upload.mjs <aab경로> [트랙] [출시노트파일]
// 인증: PLAY_SERVICE_ACCOUNT 환경변수(서비스 계정 JSON 경로), 없으면 .secrets/play-service-account.json
import {readFile} from 'node:fs/promises';
import {createReadStream} from 'node:fs';
import path from 'node:path';
import {google} from 'googleapis';

const PACKAGE_NAME = 'com.yjy.anime_checker_flutter';
const root = path.resolve(import.meta.dirname, '..');
const [aabArg, trackArg = 'production', notesArg] = process.argv.slice(2);

if (!aabArg) {
  console.error('사용법: node tools/play_upload.mjs <aab경로> [트랙] [출시노트파일]');
  process.exit(1);
}

const keyFile =
  process.env.PLAY_SERVICE_ACCOUNT ||
  path.join(root, '.secrets', 'play-service-account.json');
const aabPath = path.resolve(aabArg);
const notes = notesArg ? (await readFile(path.resolve(notesArg), 'utf8')).trim() : '';

const auth = new google.auth.GoogleAuth({
  keyFile,
  scopes: ['https://www.googleapis.com/auth/androidpublisher'],
});
const androidpublisher = google.androidpublisher({version: 'v3', auth});

const {data: edit} = await androidpublisher.edits.insert({
  packageName: PACKAGE_NAME,
});
console.log(`편집 세션 생성: ${edit.id}`);

const {data: bundle} = await androidpublisher.edits.bundles.upload({
  packageName: PACKAGE_NAME,
  editId: edit.id,
  media: {mimeType: 'application/octet-stream', body: createReadStream(aabPath)},
});
console.log(`업로드 완료: 버전 코드 ${bundle.versionCode}`);

await androidpublisher.edits.tracks.update({
  packageName: PACKAGE_NAME,
  editId: edit.id,
  track: trackArg,
  requestBody: {
    releases: [
      {
        versionCodes: [String(bundle.versionCode)],
        status: 'completed',
        releaseNotes: notes
          ? [{language: 'ko-KR', text: notes}]
          : undefined,
      },
    ],
  },
});
console.log(`${trackArg} 트랙에 배정`);

const {data: committed} = await androidpublisher.edits.commit({
  packageName: PACKAGE_NAME,
  editId: edit.id,
});
console.log(`제출 완료 (edit ${committed.id}) — Play 심사 대기 상태로 들어갑니다.`);
