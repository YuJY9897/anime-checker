// 서비스 계정 권한과 현재 프로덕션 트랙 상태를 확인한다.
import path from 'node:path';
import {google} from 'googleapis';

const PACKAGE_NAME = 'com.yjy.anime_checker_flutter';
const root = path.resolve(import.meta.dirname, '..');
const keyFile =
  process.env.PLAY_SERVICE_ACCOUNT ||
  path.join(root, '.secrets', 'play-service-account.json');

const auth = new google.auth.GoogleAuth({
  keyFile,
  scopes: ['https://www.googleapis.com/auth/androidpublisher'],
});
const androidpublisher = google.androidpublisher({version: 'v3', auth});

const {data: edit} = await androidpublisher.edits.insert({
  packageName: PACKAGE_NAME,
});
console.log(`인증 성공 — 편집 세션 ${edit.id}`);

const {data: tracks} = await androidpublisher.edits.tracks.list({
  packageName: PACKAGE_NAME,
  editId: edit.id,
});
for (const track of tracks.tracks || []) {
  const releases = (track.releases || [])
    .map((r) => `${r.name || '-'} [${r.status}] versionCodes=${(r.versionCodes || []).join(',')}`)
    .join(' | ');
  console.log(`트랙 ${track.track}: ${releases || '(비어 있음)'}`);
}

await androidpublisher.edits.delete({packageName: PACKAGE_NAME, editId: edit.id});
console.log('확인용 편집 세션 정리 완료 (변경 없음)');
