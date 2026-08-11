// Play 스토어 등록정보의 앱 아이콘(512x512)을 교체한다.
// 사용법: node tools/play_icon.mjs <아이콘경로> [언어코드]
import {createReadStream} from 'node:fs';
import path from 'node:path';
import {google} from 'googleapis';

const PACKAGE_NAME = 'com.yjy.anime_checker_flutter';
const root = path.resolve(import.meta.dirname, '..');
const [iconArg, language = 'ko-KR'] = process.argv.slice(2);

if (!iconArg) {
  console.error('사용법: node tools/play_icon.mjs <아이콘경로> [언어코드]');
  process.exit(1);
}

const keyFile =
  process.env.PLAY_SERVICE_ACCOUNT ||
  path.join(root, '.secrets', 'play-service-account.json');

const auth = new google.auth.GoogleAuth({
  keyFile,
  scopes: ['https://www.googleapis.com/auth/androidpublisher'],
});
const androidpublisher = google.androidpublisher({version: 'v3', auth});

const {data: edit} = await androidpublisher.edits.insert({packageName: PACKAGE_NAME});
console.log(`편집 세션 생성: ${edit.id}`);

await androidpublisher.edits.images.deleteall({
  packageName: PACKAGE_NAME,
  editId: edit.id,
  language,
  imageType: 'icon',
});
console.log('기존 아이콘 삭제');

const {data: uploaded} = await androidpublisher.edits.images.upload({
  packageName: PACKAGE_NAME,
  editId: edit.id,
  language,
  imageType: 'icon',
  media: {mimeType: 'image/png', body: createReadStream(path.resolve(iconArg))},
});
console.log(`업로드 완료: ${uploaded.image?.url || uploaded.image?.id}`);

await androidpublisher.edits.commit({packageName: PACKAGE_NAME, editId: edit.id});
console.log('제출 완료 — 스토어 등록정보 심사 대기 상태로 들어갑니다.');
