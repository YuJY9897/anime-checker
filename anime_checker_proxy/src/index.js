const TMDB = 'https://api.themoviedb.org/3';
const IMAGE = 'https://image.tmdb.org/t/p/w500';
const JIKAN = 'https://api.jikan.moe/v4';
const GENRES = {
  16: '애니메이션',
  35: '코미디',
  18: '드라마',
  10759: '액션/모험',
  10765: '공상과학/판타지',
  9648: '미스터리',
  10762: '키즈',
  10751: '가족',
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    try {
      if (request.method === 'OPTIONS') return cors();
      if (url.pathname === '/search') return json(await searchAnime(env, url.searchParams.get('q') || ''));
      if (url.pathname.startsWith('/anime/')) return json(await animeDetail(env, url.pathname.split('/').pop()));
      if (url.pathname === '/new-anime') {
        return json({items: await newAnime(env, url.searchParams.get('region') || 'KR', url.searchParams.get('until') || '')});
      }
      if (url.pathname === '/feedback' && request.method === 'POST') {
        const result = await saveFeedback(request, env);
        return json(result, result.ok ? 200 : 400);
      }
      if (url.pathname === '/news') return json({items: await news(url.origin)});
      if (url.pathname === '/image') return proxyImage(url.searchParams.get('url') || '');
      return json({error: 'not found'}, 404);
    } catch (error) {
      return json({error: String(error?.message || error)}, 500);
    }
  },
};

async function saveFeedback(request, env) {
  if (!env.FEEDBACK_KV) throw new Error('FEEDBACK_KV is not configured');
  const contentType = request.headers.get('content-type') || '';
  if (!contentType.includes('application/json')) return {ok: false, error: 'invalid content type'};

  const input = await request.json();
  const category = cleanText(input.category, 40) || '기타';
  const title = cleanText(input.title, 120);
  const body = cleanText(input.body, 3000);
  const email = cleanText(input.email, 160);
  const appVersion = cleanText(input.appVersion, 40);
  const clientCreatedAt = cleanText(input.createdAt, 40);
  if (body.length < 5) return {ok: false, error: 'body too short'};

  const now = new Date().toISOString();
  const id = `feedback:${now.slice(0, 10)}:${crypto.randomUUID()}`;
  const payload = {
    id,
    category,
    title,
    body,
    email,
    appVersion,
    clientCreatedAt,
    createdAt: now,
  };
  await env.FEEDBACK_KV.put(id, JSON.stringify(payload), {
    metadata: {category, createdAt: now, hasEmail: Boolean(email)},
  });
  return {ok: true, id};
}

function cleanText(value, maxLength) {
  return String(value || '')
    .replace(/[\u0000-\u001f\u007f]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, maxLength);
}
async function tmdb(env, path) {
  if (!env.TMDB_API_KEY) throw new Error('TMDB_API_KEY is not configured');
  const join = path.includes('?') ? '&' : '?';
  const response = await fetch(`${TMDB}${path}${join}api_key=${env.TMDB_API_KEY}&language=ko-KR`);
  if (!response.ok) throw new Error(`TMDB ${response.status}`);
  return response.json();
}

async function searchAnime(env, query) {
  if (!query.trim()) return {items: []};
  const data = await tmdb(env, `/search/tv?query=${encodeURIComponent(query)}&include_adult=false`);
  const results = (data.results || []).filter((item) => isAnimeTv(item) && (item.original_language === 'ja' || hasKorean(item.name)));
  return {items: results.slice(0, 20).map(toAnime)};
}

async function animeDetail(env, id) {
  if (id.startsWith('mal-')) return jikanAnimeDetail(id);
  const tv = await tmdb(env, `/tv/${id}`);
  const seasonSummaries = (tv.seasons || [])
    .filter((season) => season.season_number > 0 && season.episode_count > 0)
    .slice(0, 24);
  const seasons = await Promise.all(
    seasonSummaries.map((season) => seasonDetail(env, id, tv, season)),
  );
  return {
    ...toAnime(tv),
    seasons: seasons.filter((season) => season.episodes.length > 0),
    movies: [],
  };
}

async function jikanAnimeDetail(id) {
  const malId = id.replace(/^mal-/, '');
  const data = await jikan(`/anime/${encodeURIComponent(malId)}/full`);
  const item = data.data || {};
  const anime = applyKnownKoreanTitle(toAnimeFromJikan(item));
  if (isJikanMovie(item)) {
    return {
      ...anime,
      seasons: [],
      movies: [
        {
          id: anime.id,
          title: anime.title,
          posterUrl: anime.posterUrl,
          releaseDate: dateOnly(item.aired?.from),
          runtime: Number(item.duration?.match(/\d+/)?.[0] || 0),
        },
      ],
    };
  }
  const episodeCount = Number.isFinite(item.episodes) ? item.episodes : 0;
  const episodes = await jikanAnimeEpisodes(malId, episodeCount);
  return {
    ...anime,
    seasons: episodes.length > 0
      ? [
          {
            number: 1,
            name: '1기',
            subtitle: dateOnly(item.aired?.from),
            posterUrl: anime.posterUrl,
            episodes,
          },
        ]
      : [],
    movies: [],
  };
}
async function jikanAnimeEpisodes(malId, fallbackCount) {
  const episodes = [];
  let lastPage = 1;
  for (let page = 1; page <= Math.min(lastPage, 6); page += 1) {
    try {
      const data = await jikan(`/anime/${encodeURIComponent(malId)}/episodes?page=${page}`);
      episodes.push(...(data.data || []));
      lastPage = data.pagination?.last_visible_page || 1;
    } catch (_) {
      break;
    }
    if (page < Math.min(lastPage, 6)) await sleep(350);
  }
  if (episodes.length > 0) {
    return episodes
      .map((episode, index) => ({
        number: Number(episode.mal_id || index + 1),
        title: episode.title || `${Number(episode.mal_id || index + 1)}화`,
        airDate: dateOnly(episode.aired),
      }))
      .filter((episode) => Number.isFinite(episode.number) && episode.number > 0)
      .sort((a, b) => a.number - b.number);
  }
  return Array.from({length: fallbackCount || 0}, (_, index) => ({
    number: index + 1,
    title: `${index + 1}화`,
    airDate: '',
  }));
}
async function seasonDetail(env, tvId, tv, summary) {
  try {
    const detail = await tmdb(env, `/tv/${tvId}/season/${summary.season_number}`);
    const episodes = (detail.episodes || [])
      .filter((episode) => Number.isFinite(episode.episode_number) && episode.episode_number > 0)
      .map((episode) => ({
        number: episode.episode_number,
        title: episode.name || `${episode.episode_number}화`,
        airDate: episode.air_date || '',
      }));
    return {
      number: summary.season_number,
      name: seasonName(detail.name || summary.name, summary.season_number),
      subtitle: detail.air_date || summary.air_date || '',
      posterUrl: poster(detail.poster_path || summary.poster_path || tv.poster_path),
      episodes,
    };
  } catch (_) {
    return seasonFromSummary(tv, summary);
  }
}

function seasonFromSummary(tv, summary) {
  return {
    number: summary.season_number,
    name: seasonName(summary.name, summary.season_number),
    subtitle: summary.air_date || '',
    posterUrl: poster(summary.poster_path || tv.poster_path),
    episodes: Array.from({length: summary.episode_count || 0}, (_, index) => ({
      number: index + 1,
      title: `${index + 1}화`,
      airDate: '',
    })),
  };
}

function seasonName(name, number) {
  if (!name || /^Season\s*\d+$/i.test(name)) return `${number}기`;
  return name;
}
async function newAnime(env, region, until) {
  const today = parseDateOnly(until) || koreaToday();
  const [jikanItems, upcomingItems] = await Promise.all([
    jikanNewAnime(env, today).catch(() => []),
    jikanUpcomingAnime(today).catch(() => []),
  ]);
  const sortedItems = mergeAnimeItems([...jikanItems, ...upcomingItems])
    .sort((a, b) => releaseSort(a, b, today))
    .slice(0, 500)
    .map(applyKnownKoreanTitle);
  const enrichedItems = await enrichRecentJikanTitles(env, sortedItems);
  return dedupeAnimeItemsByTitle(enrichedItems)
    .sort((a, b) => releaseSort(a, b, today))
    .slice(0, 500);
}

async function tmdbNewAnime(env, region, today) {
  const months = monthsFromYearStart(today);
  const seen = new Set();
  const items = [];
  const monthGroups = await Promise.all(
    months.map((month) => newAnimeForMonth(env, region, month.start, month.end)),
  );
  for (const monthItems of monthGroups) {
    for (const item of monthItems) {
      const id = animeItemId(item);
      if (seen.has(id)) continue;
      seen.add(id);
      items.push(item);
    }
  }
  return items
    .filter((item) => hasKorean(animeItemTitle(item)) && animeItemDate(item) && isAnimeTv(item))
    .sort((a, b) => animeItemDate(b).localeCompare(animeItemDate(a)))
    .map(toAnime);
}

async function jikanNewAnime(env, today) {
  const releases = [];
  for (const season of jikanSeasonsFromYearStart(today)) {
    try {
      releases.push(...await jikanSeason(season.year, season.name));
    } catch (_) {
      // Keep already fetched seasons when Jikan rate-limits one season.
    }
    await sleep(700);
  }
  const items = releases
    .filter(isJikanAnimeRelease)
    .map(toAnimeFromJikan)
    .filter((item) => item.firstAirDate && parseDateOnly(item.firstAirDate)?.getFullYear() === today.getFullYear())
    .sort((a, b) => animeItemDate(b).localeCompare(animeItemDate(a)));
  return items;
}

async function jikanUpcomingAnime(today) {
  const releases = [];
  for (let page = 1; page <= 6; page += 1) {
    try {
      const data = await jikan(`/seasons/upcoming?page=${page}&sfw=true`);
      releases.push(...(data.data || []));
      if (page >= (data.pagination?.last_visible_page || 1)) break;
    } catch (_) {
      break;
    }
    await sleep(450);
  }
  return releases
    .filter(isJikanAnimeRelease)
    .map(toAnimeFromJikan)
    .filter((item) => item.firstAirDate && parseDateOnly(item.firstAirDate)?.getFullYear() === today.getFullYear())
    .sort((a, b) => animeItemDate(b).localeCompare(animeItemDate(a)));
}
async function enrichRecentJikanTitles(env, items) {
  return items;
}

async function enrichJikanTitle(env, anime) {
  if (hasKorean(anime.title)) return anime;
  const mediaTypes = anime.movies.length > 0 || /movie/i.test(anime.status) ? ['movie', 'tv'] : ['tv', 'movie'];
  const queries = [...new Set([anime.originalTitle, anime.title].filter((value) => value && value.trim().length >= 2))].slice(0, 2);
  for (const mediaType of mediaTypes) {
    for (const query of queries) {
      const match = await tmdbKoreanAnimeMatch(env, mediaType, query, anime.firstAirDate);
      if (match) {
        return {
          ...anime,
          title: animeItemTitle(match),
          posterUrl: poster(match.poster_path) || anime.posterUrl,
          genres: genreNames(match.genre_ids, match.genres).filter((name) => name !== '애니메이션').slice(0, 5),
        };
      }
    }
  }
  const fallbackTitle = knownKoreanTitle(anime.title);
  return fallbackTitle ? {...anime, title: fallbackTitle} : anime;
}

async function tmdbKoreanAnimeMatch(env, mediaType, query, date) {
  try {
    const data = await tmdb(env, `/search/${mediaType}?query=${encodeURIComponent(query)}&include_adult=false`);
    const results = (data.results || []).filter((item) => hasKorean(animeItemTitle(item)) && isAnimeResult(item));
    if (results.length === 0) return null;
    return results
      .map((item) => ({item, score: tmdbMatchScore(item, date)}))
      .sort((a, b) => b.score - a.score)[0].item;
  } catch (_) {
    return null;
  }
}

function knownKoreanTitle(title = '') {
  const patterns = [
    [/Call Up Girls/i, '콜 업 걸즈 스페셜'],
    [/Playing Sister/i, '플레잉 시스터'],
    [/Foxing/i, '폭싱: 여우 빙의'],
    [/Noto Peninsula Reconstruction/i, '노토반도 부흥 지원 프로젝트'],
    [/Vertex Force/i, '버텍스 포스'],
    [/Juuou Mujin Dandivine/i, '쥬오무진 단디바인'],
    [/Grow Up Show/i, '그로우 업 쇼: 해바라기 서커스'],
    [/Villager of Level 999/i, 'LV999의 마을사람'],
    [/Outpost: Off-Duty Tales/i, '변경의 초소 이야기'],
    [/^Eri$/i, '에리'],
    [/Boy with Gundam/i, '건담을 든 소년'],
    [/Hyakushou Kizoku/i, '백성귀족 3기'],
    [/Honkai: Star Rail/i, '붕괴: 스타레일'],
    [/Odekake Kozame/i, '외출하는 아기상어 2기'],
    [/Shou 3 Ashibe/i, '소년 아시베 QQ 고마짱'],
    [/Bloody Mary/i, '블러디 메리'],
    [/Hundred Scenes of Awajima/i, '아와지마 백경'],
    [/Drops of God/i, '신의 물방울'],
    [/Highway no Datenshi/i, '명탐정 코난: 하이웨이의 타천사'],
    [/Warrior Princess and the Barbaric King/i, '전투공주와 야만왕'],
    [/Kujima/i, '쿠지마는 노래하지 않아'],
    [/Re:ZERO/i, 'Re:제로부터 시작하는 이세계 생활'],
    [/Gals Can't Be Kind to Otaku/i, '갸루는 오타쿠에게 상냥하지 않아!?'],
    [/Ribdiculous Reincarnation/i, '갈비뼈 전생'],
    [/Pardon the Intrusion/i, '실례합니다, 다녀왔습니다!'],
    [/Eren the Southpaw/i, '왼손잡이 에렌'],
    [/Komekami! Girls/i, '코메카미! 걸즈'],
    [/Second Prettiest Girl/i, '반에서 두 번째로 귀여운 여자아이와 친구가 되었다'],
    [/Marriagetoxin/i, '마리어지 톡신'],
    [/Nippon Sangoku/i, '일본 삼국'],
    [/Liar Game/i, '라이어 게임'],
    [/Most Heretical Last Boss Queen/i, '비극의 원흉이 되는 최강외도 라스트 보스 여왕 2기'],
    [/Replica Can Fall in Love/i, '레플리카도 사랑을 한다'],
    [/Beyond Twilight/i, '황혼 너머'],
    [/Witch Hat Atelier/i, '위치 워치 아틀리에'],
    [/Farming Life in Another World/i, '이세계 느긋한 농가 2기'],
    [/Klutzy Class Monitor/i, '덜렁이 반장과 짧은 치마의 그녀'],
    [/Observation Log of My Fianc/i, '자칭 악역 영애 약혼자 관찰 기록'],
    [/Rooster Fighter/i, '니와토리 파이터'],
    [/Marika's Love Meter/i, '마리카의 사랑 게이지 이상'],
    [/Ingoku Danchi/i, '음옥단지'],
    [/Ghost Concert/i, '고스트 콘서트'],
    [/Mistress Kanan/i, '카난 님은 쉽게 넘어간다'],
    [/Needy Girl Overdose/i, '니디 걸 오버도즈'],
    [/Kusunoki's Garden of Gods|Kusunoki no Bannin/i, '쿠스노키의 파수꾼'],
    [/Food Diary of Miss Maid/i, '메이드 양의 식사 일기'],
    [/Magical Sisters Lulutto Lilly/i, '마법자매 루룻토 릴리'],
    [/Onegai AiPri/i, '부탁해 아이프리'],
    [/Daemons of the Shadow Realm/i, '황천의 츠가이'],
    [/Demon School! Iruma-kun/i, '마계학교 이루마 군 4기'],
    [/Ascendance of a Bookworm/i, '책벌레의 하극상: 영주의 양녀'],
    [/Akane-banashi/i, '아카네 이야기'],
    [/Appraiser \(Provisional\)/i, '최강 직업은 감정사입니다'],
    [/^Mao$/i, '마오'],
    [/Rilakkuma/i, '리락쿠마'],
    [/Reincarnated as a Slime Season 4/i, '전생했더니 슬라임이었던 건에 대하여 4기'],
    [/Angel Next Door/i, '옆집 천사님 때문에 어느샌가 인간적으로 타락한 사연 2기'],
    [/Petals of Reincarnation/i, '리인카네이션의 꽃잎'],
    [/Haibara's Teenage New Game/i, '하이바라의 청춘 뉴게임+'],
    [/Killed Again, Mr\. Detective/i, '또 죽었습니까, 탐정님'],
    [/Snowball Earth/i, '스노볼 어스'],
    [/Monster Eater/i, '몬스터 이터'],
    [/Kirio Fan Club/i, '키리오 팬클럽'],
    [/Dark History of the Reincarnated Villainess/i, '전생 악녀의 흑역사'],
    [/Dr\. Stone/i, '닥터 스톤: 사이언스 퓨처 Part 3'],
    [/Ramparts of Ice/i, '얼음 성벽'],
    [/Nakamura-kun/i, '힘내라! 나카무라 군!!'],
    [/Always a Catch/i, '언제나 좋은 조건!'],
    [/Classroom of the Elite/i, '어서 오세요 실력지상주의 교실에 4기'],
    [/Dorohedoro/i, '도로헤도로 2기'],
    [/Vending Machine/i, '자동판매기로 다시 태어난 나는 미궁을 방랑한다 3기'],
    [/Great Sage Riddle/i, '대현자 리들의 회귀'],
    [/Agents of the Four Seasons/i, '사계절 대행자: 봄의 춤'],
    [/Assassination Classroom/i, '암살교실 더 무비: 우리의 시간'],
    [/étoile de Paris/i, '꽃피는 파리의 별'],
    [/New Dawn/i, '새로운 새벽'],
    [/Tears of the Azure Sea/i, '전생했더니 슬라임이었던 건에 대하여 극장판: 푸른 바다의 눈물'],
    [/Doraemon the Movie 2026/i, '도라에몽 극장판 2026'],
    [/Gintama Movie/i, '은혼 극장판: 요시와라 대염상'],
    [/Star Detective Precure/i, '스타 탐정 프리큐어!'],
    [/Mobile Suit Gundam: Hathaway/i, '기동전사 건담: 섬광의 하사웨이'],
    [/Kaya-chan Isn't Scary/i, '카야쨩은 무섭지 않아'],
    [/Villainess Is Adored/i, '악역 영애는 이웃나라 왕태자의 사랑을 받는다'],
    [/Scum of the Brave/i, '용사의 쓰레기'],
    [/Misanthrope Teaches/i, '인간혐오 교사가 아인반을 맡았습니다'],
    [/Oedo Fire Slayer/i, '오에도 화재 해결사'],
    [/Dragon Hatchling/i, '전생했더니 드래곤의 알이었다'],
    [/Dead Account/i, '데드 어카운트'],
    [/Dark Moon/i, '다크 문: 달의 제단'],
    [/Gunma/i, '너는 아직 군마를 모른다 Reiwa판'],
    [/Cardfight!! Vanguard/i, '카드파이트!! 뱅가드'],
    [/Hoppe-chan/i, '홋페짱'],
    [/Roll Over and Die/i, '굴러라 그리고 죽어라'],
    [/Champignon Witch/i, '샹피뇽의 마녀'],
    [/All You Need Is Kill/i, '올 유 니드 이즈 킬'],
    [/Kimengumi/i, '하이스쿨! 기면조'],
    [/Holy Grail of Eris/i, '에리스의 성배'],
    [/Invisible Man/i, '투명남과 인간여자'],
    [/Gentle Noble's Vacation/i, '온화한 귀족의 휴가 추천'],
    [/Demon King's Daughter/i, '마왕의 딸은 너무 착해!!'],
    [/Darwin Incident/i, '더 다윈 인시던트'],
    [/Daily Grind at Age 29/i, '29세 독신 중견 모험가의 일상'],
    [/Case Book of Arne/i, '아르네의 사건부'],
    [/Childhood Friends/i, '소꿉친구로는 러브 코미디를 할 수 없어'],
    [/Yoroi-Shinden Samurai Troopers/i, '요로이 신전 사무라이 트루퍼스'],
    [/Favorite Stepbrother/i, '최애 의붓오빠를 오래 사랑하기 위해 장수하겠습니다'],
    [/Wash It All Away/i, '전부 씻어내자'],
    [/Part-time Torturer/i, '아르바이트 고문관의 일상'],
    [/^Labyrinth$/i, '라비린스'],
    [/Killtube/i, '킬튜브'],
    [/Grotesqqque/i, '그로테스크'],
    [/Daisy's Life/i, '데이지의 인생'],
    [/Maebashi Witches/i, '마에바시 위치스'],
    [/Watashi no Shiawase na Kekkon/i, '나의 행복한 결혼 스페셜'],
    [/Norman the Snowman/i, '눈사람 노먼'],
    [/Armored Trooper Votoms/i, '장갑기병 보톰즈'],
    [/Minky Momo/i, '요술공주 밍키 모모'],
    [/Choujun! Choujou-senpai/i, '초순! 초죠 선배'],
    [/Junket Bank/i, '정킷 뱅크'],
    [/Tensei Goblin/i, '전생 고블린입니다만 질문 있나요?'],
    [/Tetsuryou/i, '철도무스메와 만나다'],
    [/Tennis no Oujisama/i, '신 테니스의 왕자'],
    [/Dark Summoner/i, '어둠 소환사와 사귀고 있습니다'],
    [/Ojisan wa Kawaii/i, '아저씨는 귀여운 것을 좋아해'],
    [/Girlfriend's Friend/i, '내 여자친구의 친구'],
    [/Horror Collector/i, '호러 컬렉터'],
    [/Seven Knights of the Marronnier/i, '마로니에 왕국의 7인의 기사'],
    [/Battle Spirits/i, '배틀 스피리츠'],
    [/Tanuki to Kitsune/i, '너구리와 여우'],
    [/Sirotan/i, '시로탄'],
    [/Yuruyuru Zukan/i, '유루유루 도감'],
    [/We Are Aliens/i, '위 아 에일리언즈'],
    [/Meitantei Precure/i, '명탐정 프리큐어!'],
    [/Shiranuhi/i, '시라누이'],
    [/Ribbon Hero/i, '리본 히어로'],
    [/Demon Agent/i, '데몬 에이전트'],
    [/Chiikawa Movie/i, '치이카와 극장판'],
    [/All Wishes Come True/i, '모든 소원이 이루어진다'],
    [/Cyborg 009/i, '사이보그 009'],
    [/Hanabi to Yakusoku/i, '너와 불꽃과 약속'],
    [/Hanaori-san/i, '하나오리 씨는 다음 생에도 싸우고 싶어'],
    [/Planosaurus/i, '플라노사우루스'],
    [/Mebius Dust/i, '메비우스 더스트'],
    [/Thunder 3/i, '썬더 3'],
    [/Red River/i, '하늘은 붉은 강가'],
    [/Victoria of Many Faces/i, '여러 얼굴의 빅토리아'],
    [/Stepmother and Stepsisters/i, '새어머니와 의붓자매들이 나쁘지 않아'],
    [/Perfect Addiction/i, '퍼펙트 애딕션'],
    [/Young Ladies Don't Play Fighting Games/i, '대전 감사합니다'],
    [/Migawari Reijou/i, '대역 영애를 구한 것은 냉혹한 얼음 왕자의 사랑이었습니다'],
    [/Majo no Tani/i, '마녀의 계곡의 밤'],
    [/Wrong About Her/i, '그녀에 대해 완전히 착각했다'],
    [/Love Unseen/i, '맑은 밤하늘 아래 보이지 않는 사랑'],
    [/Goodbye, Lara/i, '굿바이, 라라'],
    [/Insipid Prince/i, '무능 왕자의 은밀한 왕위 쟁탈'],
    [/Livid Lady/i, '격노한 영애의 복수 지침'],
    [/Forsaken Saintess/i, '버림받은 성녀와 이세계 미식 여행'],
    [/Azur Lane/i, '벽람항로: 미속전진! 2기'],
    [/Dodge Danko/i, '불꽃 투구소녀 돗지 단코'],
    [/Meisaku-kun/i, '아와레! 명작군'],
    [/Rich Girl Caretaker/i, '부잣집 학교의 인기녀를 돌보는 비밀 간병인'],
    [/One Piece: Heroines/i, '원피스: 히로인즈'],
    [/Strongest Rearguard/i, '세계 최강의 후위'],
    [/Magilumiere/i, '주식회사 마지루미에 2기'],
    [/Lyrical Nanoha/i, '마법소녀 리리컬 나노하 EXCEEDS'],
    [/Duke.s Son/i, '공작가 도련님은 사랑하지 않는다면서 익애한다'],
    [/Iron Wok Jan/i, '철냄비짱!'],
    [/Kaikigumi/i, '가자 괴기조'],
    [/Tomica & Tom/i, '토미카와 톰 2기'],
    [/To You in the Beyond/i, '저 너머의 너에게'],
    [/Little Brothers/i, '동생들이 폐를 끼칩니다'],
    [/Iwamoto-Senpai/i, '이와모토 선배의 추천'],
    [/KAMUI/i, '카무이'],
    [/Bananya/i, '바나냐: 집에서 파티'],
    [/Babies of Bread/i, '빵 아기들'],
    [/Kaiju Girl Caramelise/i, '괴수 소녀 카라멜라이즈'],
    [/10 Year-Long Last Stand/i, '10년 최후의 저항 끝에 전설이 되었다'],
    [/Frontier Lord Begins/i, '영지민 0명으로 시작하는 변경 영주님'],
    [/Draw This, Then Die/i, '그리고 죽어라'],
    [/Cosmic Princess Kaguya/i, '코스믹 프린세스 카구야!'],
    [/Clear Moonlit Dusk/i, '달밤에 비치는 그대'],
    [/Hell Mode/i, '헬 모드'],
    [/Easygoing Territory Defense/i, '느긋한 영지 방어'],
    [/Noble Reincarnation/i, '고귀한 전생'],
    [/Shiboyugi/i, '시보유기'],
    [/Cute Girl in the Hero/i, '용사 파티에 귀여운 아이가 있어서 고백해봤다'],
    [/Midnight Heart/i, '한밤중 하트튠'],
    [/Jack-of-All-Trades/i, '만능 잡역부의 파티 생활'],
    [/Journal with Witch/i, '마녀와의 일지'],
    [/Tamon's B-Side/i, '타몬 군 지금 어느 쪽?!'],
    [/Kunon the Sorcerer/i, '마술사 쿠논은 보인다'],
    [/Sentenced to Be a Hero/i, '형벌용사 9004대'],
    [/Rakuen Tsuihou/i, '낙원추방: 마음의 레조넌스'],
    [/Girls & Panzer/i, '걸즈 앤 판처 최종장 Part 5'],
    [/Aoashi/i, '아오아시 2기'],
    [/Broken Saintess/i, '상처투성이 성녀의 복수 2기'],
    [/Appraisal Skill/i, '전생 귀족, 감정 스킬로 성공하다 3기'],
    [/Sasaki and Peeps/i, '사사키와 피짱 2기'],
    [/Dragon Ball Super/i, '드래곤볼 슈퍼'],
    [/Ranma/i, '란마 1/2 3기'],
    [/Firefly Wedding/i, '반딧불이의 혼례'],
    [/Tougen Anki/i, '도원암귀: 닛코 케곤 폭포편'],
    [/Iceblade Sorcerer/i, '빙검의 마술사가 세계를 다스린다 2기'],
    [/Secret Saint/i, '비밀의 성녀 이야기'],
    [/Magic Knight Rayearth/i, '마법기사 레이어스'],
    [/Psyren/i, '사이렌'],
    [/Mahou Shoujo Ikusei Keikaku/i, '마법소녀 육성계획 restart'],
    [/Toaru Anbu no Item/i, '어떤 암부의 아이템'],
    [/Nia Liston/i, '광란영애 니아 리스톤'],
    [/Space Mercenary/i, '우주 용병으로 전생했습니다'],
    [/Magical.*Explorer/i, '매지컬 익스플로러'],
    [/Love Potion/i, '짝사랑 상대가 사랑의 묘약을 의뢰한 마녀입니다'],
    [/Shiotaiou no Satou-san/i, '시오 대응의 사토 씨는 나에게만 달콤하다'],
    [/Yowaki Max Reijou/i, '약한 척 영애는 완벽한 약혼자의 내기에 올라탔다'],
    [/Vermilion Mask/i, '주홍빛 가면'],
    [/Hotel Inhumans/i, '호텔 인휴먼즈 2기'],
    [/Overgeared/i, '템빨'],
    [/#?I'm Looking for Zombie|Zombie/i, '좀비를 찾습니다'],
    [/Tank Chair/i, '탱크 체어'],
    [/Cheat Fuyo Majutsushi/i, '추방당한 치트 부여 마술사'],
    [/Ace of Diamond/i, '다이아몬드 에이스 Act II 2기 Part 2'],
    [/Suikoden/i, '환상수호전 애니메이션'],
    [/Revo Barai/i, '빌려준 마력은 리보払い로 강제 징수'],
    [/Sekai Saikyou no Majo/i, '세계 최강의 마녀, 시작했습니다'],
    [/Sekiro/i, '세키로: 노 디피트'],
    [/Inept Villainess/i, '불우직 영애입니다만'],
    [/Love You Till Your Dying Day/i, '네가 죽을 때까지 사랑하고 싶어'],
    [/Sparks of Tomorrow/i, '내일의 불꽃'],
    [/Black Torch/i, '블랙 토치'],
    [/Jaadugar/i, '몽골의 마녀 자두가르'],
    [/Exiled Heavy Knight/i, '추방된 중기사는 게임 지식으로 무쌍한다'],
    [/Chainsmoker Cat/i, '체인스모커 캣'],
    [/Bungo Stray Dogs Wan/i, '문호 스트레이독스 멍! 2'],
    [/Hana-Kimi/i, '아름다운 그대에게 2기'],
    [/Dara-san of Reiwa/i, '레이와의 다라 씨'],
    [/BanG Dream/i, '뱅드림! 유메미타'],
    [/Oblivious Saint/i, '무자각한 성녀는 오늘도 무의식적으로 힘을 흘린다'],
    [/World Is Dancing/i, '월드 이즈 댄싱'],
    [/Cat and the Dragon/i, '고양이와 용'],
    [/Overshadowed to Overpowered|Talentless Sage/i, '낙제 현자의 학원 무쌍'],
    [/All-Works Maid/i, '히로인? 성녀? 아니요, 올 워크스 메이드입니다!'],
    [/Bleach/i, '블리치: 천년혈전편'],
    [/Elusive Samurai/i, '도망을 잘 치는 도련님 2기'],
    [/Keroro Gunsou/i, '개구리 중사 케로로'],
    [/Baki/i, '바키도'],
    [/Mr\. Osomatsu|Osomatsu/i, '오소마츠상'],
    [/Detective Conan/i, '명탐정 코난'],
    [/Smoking Behind the Supermarket/i, '슈퍼 뒤에서 담배 피우는 두 사람'],
    [/Mononoke/i, '모노노케'],
    [/Patlabor/i, '기동경찰 패트레이버'],
    [/Irregular at Magic High School/i, '마법과고교의 열등생'],
    [/Love Live/i, '러브 라이브!'],
    [/My Hero Academia/i, '나의 히어로 아카데미아'],
    [/Puella Magi Madoka Magica/i, '마법소녀 마도카 마기카'],
    [/Saga of Tanya the Evil/i, '유녀전기 2기'],
    [/Mushoku Tensei/i, '무직전생 3기'],
    [/Sword Art Online/i, '소드 아트 온라인'],
    [/Ghost in the Shell/i, '공각기동대'],
    [/Grand Blue/i, '그랑블루'],
    [/Crayon Shin-chan/i, '짱구는 못말려'],
    [/Sound! Euphonium/i, '울려라! 유포니엄'],
    [/Isekai Office Worker/i, '이세계의 사태는 사축 나름 OVA'],
    [/Does It Count If You Lose Your Innocence to an Android/i, '안드로이드는 경험 인원에 들어가나요?? 스페셜'],
    [/Dreaming of a Whale/i, '고래를 꿈꾸다'],
    [/I Want You To Show Me Your Panties/i, '싫은 얼굴을 하면서 팬티를 보여줬으면 좋겠어 Returns'],
    [/Dandelion/i, '댄더라이언'],
    [/Candy Caries/i, '캔디 카리에스'],
    [/I Want to End This Love Game/i, '사랑해 게임을 끝내고 싶어'],
    [/Wistoria/i, '지팡이와 검의 위스토리아 2기'],
    [/Mission: Yozakura Family/i, '요자쿠라 일가의 대작전 2기'],
    [/The Classroom of a Black Cat and a Witch/i, '검은 고양이와 마녀의 교실'],
    [/Ichijyoma Mankitsu Gurashi/i, '한 칸 만끽 생활!'],
    [/Kill Blue/i, '킬 블루'],
    [/Botan Kamiina/i, '카미이나 보탄, 취하면 백합꽃'],
    [/Rent-a-Girlfriend/i, '여친, 빌리겠습니다 5기'],
    [/Yowayowa Sensei/i, '요와요와 선생'],
    [/Hokuto no Ken|Fist of the North Star/i, '북두의 권'],
    [/I Got a Cheat Skill in Another World/i, '이세계에서 치트 능력을 손에 넣은 나는 현실세계에서도 무쌍한다'],
    [/AnimeJapan Awards/i, 'AnimeJapan 어워드'],
    [/iDOLM@STER Million Live/i, '아이돌마스터 밀리언 라이브!'],
    [/Entotsu Machi no Poupelle/i, '굴뚝마을의 푸펠: 약속의 시계탑'],
    [/PetitCure/i, '쁘띠큐어: 프리큐어 페어리즈 3기'],
    [/Fate\/Grand Order: Fujimaru Ritsuka/i, 'Fate/Grand Order 후지마루 리츠카는 잘 모르겠다 3기 스페셜'],
    [/Oshirimae Man/i, '오시리마에 맨: 부활의 오시리마에 제국'],
    [/Steel Ball Run|JoJo/i, '스틸 볼 런: 죠죠의 기묘한 모험'],
    [/Himitsu no AiPri/i, '비밀의 아이프리 극장판'],
    [/Beastars/i, '비스타즈 파이널 시즌 Part 2'],
    [/Fatal Fury/i, '아랑전설: 시티 오브 더 울브스'],
    [/Evangelion/i, '에반게리온 30주년 특별 상영'],
    [/Sakuna: Of Rice and Ruin/i, '천수의 사쿠나히메 코코로와 벼농사 일지'],
    [/Boku no Kokoro no Yabai Yatsu/i, '내 마음의 위험한 녀석 극장판'],
    [/Milky.*Subway/i, '은하특급 밀키 서브웨이 극장판'],
    [/Duel Masters LOST/i, '듀얼 마스터즈 LOST 망각의 태양'],
    [/Luca/i, '루카'],
    [/The Horrors' Horror Home/i, '더 호러스 호러 홈'],
    [/Princess Principal/i, '프린세스 프린서플 Crown Handler 4'],
    [/Medalist/i, '메달리스트 2기'],
    [/Gelpiyo/i, '겔피요'],
    [/Frieren/i, '장송의 프리렌 2기'],
    [/Love Through a Prism/i, '프리즘 윤무곡'],
    [/Oshi No Ko/i, '최애의 아이 3기'],
    [/Torture.*Princess/i, '공주님 고문의 시간입니다 2기'],
    [/Theatre of Darkness|Yamishibai/i, '어둠극장 16기'],
    [/Hell's Paradise/i, '지옥락 2기'],
    [/Fire Force/i, '불꽃 소방대 3기 Part 2'],
    [/Trigun Stargaze/i, '트라이건 스타게이즈'],
    [/Jujutsu Kaisen/i, '주술회전 사멸회유 전편'],
    [/Anyway, I'm Falling in Love with You/i, '어차피, 사랑하고 말 거야 2기'],
    [/Chained Soldier/i, '마도정병의 슬레이브 2기'],
    [/Hell Teacher|Jigoku Sensei Nube/i, '지옥선생 누베 Part 2'],
    [/Golden Kamuy/i, '골든 카무이 최종장'],
    [/MF Ghost/i, 'MF 고스트 3기'],
    [/Fate\/strange Fake/i, '페이트/스트레인지 페이크'],
    [/Witch on the Holy Night/i, '마법사의 밤'],
    [/There's No Freaking Way I'll be Your Lover/i, '내가 연인이 될 수 있을 리 없잖아, 무리무리!'],
    [/Cyberpunk: Edgerunners/i, '사이버펑크: 엣지러너 2'],
    [/Blue Miburo/i, '푸른 미부로 2기'],
    [/Apothecary Diaries Movie/i, '약사의 혼잣말 극장판'],
    [/The Apothecary Diaries Season 3/i, '약사의 혼잣말 3기'],
    [/Made in Abyss/i, '메이드 인 어비스: 눈뜨는 신비'],
    [/Rascal Does Not Dream/i, '청춘 돼지는 디어 프렌드의 꿈을 꾸지 않는다'],
    [/Blue Box/i, '푸른 상자 2기'],
    [/Tokyo Revengers/i, '도쿄 리벤저스: 삼천항쟁편'],
    [/Reincarnated as a Sword/i, '전생했더니 검이었습니다 2기'],
    [/Black Clover/i, '블랙 클로버 2기'],
    [/The Detective Is Already Dead/i, '탐정은 이미 죽었다 2기'],
    [/Trapped in a Dating Sim/i, '여성향 게임 세계는 모브에게 가혹한 세계입니다 2기'],
    [/Clevatess/i, '클레바테스 2기'],
    [/Fate\/strange Fake/i, '페이트/스트레인지 페이크'],
    [/From Old Country Bumpkin to Master Swordsman/i, '시골 아저씨, 검성이 되다 2기'],
    [/Skeleton Knight in Another World/i, '해골기사님은 지금 이세계 모험 중 2기'],
    [/You and I Are Polar Opposites/i, '정반대인 너와 나 2기'],
    [/The 100 Girlfriends/i, '너를 너무너무너무너무 좋아하는 100명의 그녀 3기'],
  ];
  return patterns.find(([pattern]) => pattern.test(title))?.[1] || '';
}
function tmdbMatchScore(item, date) {
  const itemDate = animeItemDate(item);
  const sameYear = itemDate && date && itemDate.slice(0, 4) === date.slice(0, 4);
  return (sameYear ? 8 : 0) +
    (item.original_language === 'ja' ? 4 : 0) +
    (Array.isArray(item.genre_ids) && item.genre_ids.includes(16) ? 2 : 0) +
    (item.poster_path ? 1 : 0);
}

function isAnimeResult(item) {
  return Array.isArray(item.genre_ids) && item.genre_ids.includes(16) && (!item.original_language || item.original_language === 'ja');
}

async function jikanSeason(year, season) {
  const items = [];
  let lastPage = 1;
  for (let page = 1; page <= Math.min(lastPage, 6); page += 1) {
    try {
      const data = await jikan(`/seasons/${year}/${season}?page=${page}&sfw=true`);
      items.push(...(data.data || []));
      lastPage = data.pagination?.last_visible_page || 1;
    } catch (error) {
      if (items.length > 0) break;
      throw error;
    }
    if (page < Math.min(lastPage, 6)) await sleep(450);
  }
  return items;
}

async function jikan(path) {
  const response = await fetch(`${JIKAN}${path}`, {
    headers: {
      accept: 'application/json',
      'user-agent': 'anime-checker-worker',
    },
    signal: AbortSignal.timeout(9000),
  });
  if (!response.ok) throw new Error(`Jikan ${response.status}`);
  return response.json();
}

async function newAnimeForMonth(env, region, start, end) {
  const [providerItems, broadItems, movies] = await Promise.all([
    discoverNewAnime(env, start, end, {
      watch_region: region,
      with_watch_monetization_types: 'flatrate|ads|free',
    }),
    discoverNewAnime(env, start, end, {}),
    discoverNewAnimeMovies(env, start, end),
  ]);
  return [...providerItems, ...broadItems, ...movies];
}

async function discoverNewAnime(env, start, end, extraParams) {
  const items = [];
  for (let page = 1; page <= 4; page += 1) {
    const params = new URLSearchParams({
      'first_air_date.gte': isoDate(start),
      'first_air_date.lte': isoDate(end),
      sort_by: 'first_air_date.desc',
      with_original_language: 'ja',
      with_genres: '16',
      page: String(page),
      ...extraParams,
    });
    const data = await tmdb(env, `/discover/tv?${params.toString()}`);
    items.push(...(data.results || []));
    if (page >= (data.total_pages || 1)) break;
  }
  return items;
}

async function discoverNewAnimeMovies(env, start, end) {
  const items = [];
  for (let page = 1; page <= 4; page += 1) {
    const params = new URLSearchParams({
      'primary_release_date.gte': isoDate(start),
      'primary_release_date.lte': isoDate(end),
      sort_by: 'primary_release_date.desc',
      with_original_language: 'ja',
      with_genres: '16',
      'with_runtime.gte': '40',
      page: String(page),
    });
    const data = await tmdb(env, `/discover/movie?${params.toString()}`);
    items.push(...(data.results || []).map((item) => ({...item, anime_checker_type: 'movie', status: '영화'})));
    if (page >= (data.total_pages || 1)) break;
  }
  return items;
}

async function news(origin) {
  const text = await fetchNewsRss();
  if (!text) return fallbackNews();
  const items = [...text.matchAll(/<item>([\s\S]*?)<\/item>/g)]
    .slice(0, 20)
    .filter((match) => isRelevantNews(decode(xml(match[1], 'title')).replace(/ - .*$/, '')));
  const parsed = await Promise.all(items.map(async (match, index) => {
    const item = match[1];
    const title = decode(xml(item, 'title')).replace(/ - .*$/, '');
    const source = decode(xml(item, 'source') || xml(item, 'News:Source'));
    const url = normalizeNewsUrl(decode(xml(item, 'link')));
    const date = new Date(decode(xml(item, 'pubDate')) || Date.now()).toISOString();
    const article = index < 6 ? await articleMeta(url) : {imageUrl: '', url};
    return {
      id: `news-${index}-${hash(url)}`,
      title,
      summary: title,
      source,
      date,
      imageUrl: article.imageUrl ? `${origin}/image?url=${encodeURIComponent(article.imageUrl)}` : '',
      url: article.url || url,
    };
  }));
  return parsed;
}

async function fetchNewsRss() {
  const googleQuery = encodeURIComponent('애니 신작 OR 애니 시즌 OR 극장판 애니 OR 애니 흥행');
  const bingQuery = encodeURIComponent('애니 신작 극장판 시즌 흥행');
  const feeds = [
    `https://news.google.com/rss/search?q=${googleQuery}&hl=ko&gl=KR&ceid=KR:ko`,
    `https://www.bing.com/news/search?q=${bingQuery}&format=rss&cc=KR`,
  ];
  for (const feed of feeds) {
    const text = await fetchRssText(feed);
    if (text) return text;
  }
  return '';
}

async function fetchRssText(url) {
  try {
    const response = await fetch(url, {
      headers: {
        'accept': 'application/rss+xml, application/xml, text/xml',
        'accept-language': 'ko-KR,ko;q=0.9,en;q=0.7',
        'user-agent': 'Mozilla/5.0 anime-checker-news',
      },
      signal: AbortSignal.timeout(4500),
    });
    if (!response.ok) return '';
    return await response.text();
  } catch (_) {
    return '';
  }
}

function fallbackNews() {
  return [
    {
      id: 'news-fallback',
      title: '애니 소식을 가져오지 못했어요',
      summary: '잠시 후 새로고침하면 다시 시도합니다.',
      source: '애니 체크',
      date: new Date().toISOString(),
      imageUrl: '',
      url: '',
    },
  ];
}

async function articleMeta(url) {
  const empty = {imageUrl: '', url};
  if (!url.startsWith('https://')) return empty;
  try {
    const response = await fetch(url, {
      redirect: 'follow',
      headers: {'user-agent': 'Mozilla/5.0 anime-checker-news-image'},
      signal: AbortSignal.timeout(1200),
    });
    if (!response.ok) return empty;
    const type = response.headers.get('content-type') || '';
    if (!type.includes('text/html')) return {...empty, url: response.url || url};
    const html = await response.text();
    return {
      imageUrl: imageMeta(html),
      url: response.url || url,
    };
  } catch (_) {
    return empty;
  }
}

async function proxyImage(rawUrl) {
  if (!rawUrl.startsWith('https://')) return json({error: 'invalid image url'}, 400);
  const response = await fetch(rawUrl);
  const type = response.headers.get('content-type') || '';
  if (!response.ok || !type.startsWith('image/')) return json({error: 'not image'}, 400);
  return new Response(response.body, {headers: {'content-type': type, 'cache-control': 'public, max-age=86400'}});
}

function releaseSort(a, b, today) {
  const aFuture = isFutureRelease(a, today);
  const bFuture = isFutureRelease(b, today);
  if (aFuture !== bFuture) return aFuture ? 1 : -1;
  return animeItemDate(b).localeCompare(animeItemDate(a));
}

function isFutureRelease(item, today) {
  const date = parseDateOnly(animeItemDate(item));
  if (!date) return false;
  const todayOnly = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  return date > todayOnly;
}
function mergeAnimeItems(items) {
  const merged = new Map();
  for (const item of items) {
    const key = `${animeItemDate(item)}:${normalizeTitle(animeItemTitle(item))}` || item.id;
    const current = merged.get(key);
    if (!current || animeCompleteness(item) > animeCompleteness(current)) merged.set(key, item);
  }
  return [...merged.values()];
}

function dedupeAnimeItemsByTitle(items) {
  const merged = [];
  const keyToIndex = new Map();
  for (const item of items.map(applyKnownKoreanTitle)) {
    const keys = animeTitleKeys(item);
    const index = keys.map((key) => keyToIndex.get(key)).find((value) => value !== undefined);
    if (index === undefined) {
      const nextIndex = merged.push(item) - 1;
      for (const key of keys) keyToIndex.set(key, nextIndex);
    } else if (animeCompleteness(item) > animeCompleteness(merged[index])) {
      merged[index] = item;
      for (const key of keys) keyToIndex.set(key, index);
    }
  }
  return merged;
}

function animeTitleKeys(item) {
  return [
    animeItemTitle(item),
    item.originalTitle,
    knownKoreanTitle(animeItemTitle(item)),
    knownKoreanTitle(item.originalTitle),
  ]
    .map(normalizeTitle)
    .filter((value, index, values) => value && values.indexOf(value) === index);
}

function applyKnownKoreanTitle(anime) {
  if (hasKorean(animeItemTitle(anime))) return anime;
  const fallbackTitle = knownKoreanTitle(animeItemTitle(anime)) || knownKoreanTitle(anime.originalTitle);
  return fallbackTitle ? {...anime, title: fallbackTitle} : anime;
}

function animeCompleteness(item) {
  return (hasKorean(animeItemTitle(item)) ? 8 : 0) +
    (item.posterUrl ? 4 : 0) +
    ((item.genres || []).length > 0 ? 2 : 0) +
    (String(item.id || '').startsWith('mal-') ? 0 : 1);
}

function normalizeTitle(value) {
  return String(value || '').toLowerCase().replace(/[^\p{L}\p{N}]+/gu, '');
}

function toAnimeFromJikan(item) {
  return {
    id: `mal-${item.mal_id}`,
    title: jikanTitle(item),
    originalTitle: item.title_japanese || item.title || '',
    posterUrl: jikanPoster(item),
    genres: jikanGenres(item),
    status: jikanStatus(item.status),
    weekday: jikanWeekday(item.broadcast?.day),
    firstAirDate: dateOnly(item.aired?.from),
    seasons: [],
    movies: [],
    dropped: false,
  };
}

function jikanTitle(item) {
  const titles = Array.isArray(item.titles) ? item.titles.map((title) => title.title || '') : [];
  return titles.find(hasKorean) || item.title_english || item.title || item.title_japanese || '';
}

function jikanPoster(item) {
  return item.images?.webp?.large_image_url || item.images?.jpg?.large_image_url || item.images?.jpg?.image_url || '';
}

function jikanGenres(item) {
  const names = [
    ...(item.genres || []),
    ...(item.explicit_genres || []),
    ...(item.themes || []),
    ...(item.demographics || []),
  ].map((genre) => jikanGenreName(genre.name)).filter(Boolean);
  return [...new Set(names)].filter((name) => name !== '애니메이션').slice(0, 5);
}

function jikanGenreName(name = '') {
  const mapped = {
    Action: '액션',
    Adventure: '모험',
    'Avant Garde': '실험',
    'Award Winning': '수상작',
    'Boys Love': '보이즈 러브',
    Comedy: '코미디',
    Drama: '드라마',
    Ecchi: '에치',
    Fantasy: '판타지',
    'Girls Love': '걸즈 러브',
    Gourmet: '요리',
    Horror: '공포',
    Mystery: '미스터리',
    Romance: '로맨스',
    'Sci-Fi': '공상과학',
    'Slice of Life': '일상',
    Sports: '스포츠',
    Supernatural: '초자연',
    Suspense: '서스펜스',
    School: '학원',
    Seinen: '성인',
    Shoujo: '순정',
    Shounen: '소년',
    Josei: '여성향',
    Kids: '키즈',
    'Adult Cast': '성인 주인공',
    Anthropomorphic: '의인화',
    CGDCT: '일상 소녀',
    Childcare: '육아',
    'Combat Sports': '격투 스포츠',
    Crossdressing: '여장',
    Delinquents: '불량배',
    Detective: '탐정',
    Educational: '교육',
    Gag: '개그',
    Gore: '고어',
    Harem: '하렘',
    'High Stakes Game': '두뇌 게임',
    Historical: '시대극',
    Idols: '아이돌',
    Isekai: '이세계',
    Iyashikei: '힐링',
    'Love Polygon': '삼각관계',
    'Magical Sex Shift': '성별전환',
    'Mahou Shoujo': '마법소녀',
    'Martial Arts': '무술',
    Mecha: '메카',
    Medical: '의학',
    Military: '밀리터리',
    Music: '음악',
    Mythology: '신화',
    Otaku: '오타쿠',
    Parody: '패러디',
    'Performing Arts': '공연예술',
    Pets: '반려동물',
    Psychological: '심리',
    Racing: '레이싱',
    Reincarnation: '환생',
    'Reverse Harem': '역하렘',
    Samurai: '사무라이',
    'Showbiz': '연예계',
    Space: '우주',
    'Strategy Game': '전략 게임',
    'Super Power': '초능력',
    Survival: '생존',
    'Team Sports': '단체 스포츠',
    'Time Travel': '시간여행',
    Vampire: '뱀파이어',
    'Video Game': '비디오 게임',
    'Visual Arts': '미술',
    Workplace: '직장',
  }[name];
  if (mapped) return mapped;
  return /[A-Za-z]/.test(name) ? '' : name;
}

function jikanStatus(status = '') {
  return {
    'Currently Airing': '방영중',
    'Not yet aired': '방영 예정',
    'Finished Airing': '방영 종료',
  }[status] || status;
}

function jikanWeekday(day = '') {
  return {
    Mondays: '월요일',
    Tuesdays: '화요일',
    Wednesdays: '수요일',
    Thursdays: '목요일',
    Fridays: '금요일',
    Saturdays: '토요일',
    Sundays: '일요일',
  }[day] || '';
}

function isJikanAnimeRelease(item) {
  if (!item?.mal_id || !dateOnly(item.aired?.from)) return false;
  if (String(item.rating || '').startsWith('Rx')) return false;
  const allowedTypes = new Set(['TV', 'ONA', 'OVA', 'Movie', 'TV Special']);
  return allowedTypes.has(item.type) && !isClearlyNonJapaneseJikan(item);
}

function isClearlyNonJapaneseJikan(item) {
  if (/[가-힣]/.test(item.title_japanese || '')) return true;
  const names = [
    ...(item.studios || []),
    ...(item.producers || []),
    ...(item.licensors || []),
  ].map((entry) => entry.name || '').join(' ');
  return /(Xiuxian|Shi Wangzhe|Ruguo Lishi|Tencent|bilibili|iQIYI|Youku|China Literature|Yuewen|Fanqie|B\.CMAY|Thundray|Sparkly Key|Wonder Cat|Original Force|Shenman|Yien Animation|Flying Fish|Guangzhou|Haoliners|Motion Magic|Colored Pencil|PB Animation|ASK Animation)/i.test(names + ' ' + (item.title || ''));
}

function isJikanMovie(item) {
  return item.type === 'Movie';
}
function toAnime(item) {
  return {
    id: animeItemId(item),
    title: animeItemTitle(item),
    originalTitle: item.original_name || item.original_title || '',
    posterUrl: poster(item.poster_path),
    genres: genreNames(item.genre_ids, item.genres),
    status: item.status || '',
    weekday: '',
    firstAirDate: animeItemDate(item),
    seasons: [],
    movies: [],
    dropped: false,
  };
}

function animeItemTitle(item) {
  return item.name || item.title || '';
}

function animeItemId(item) {
  return `${item.anime_checker_type === 'movie' ? 'movie-' : ''}${item.id}`;
}

function animeItemDate(item) {
  return item.firstAirDate || item.first_air_date || item.release_date || '';
}

function poster(path) {
  return path ? `${IMAGE}${path}` : '';
}

function hasKorean(value = '') {
  return /[가-힣]/.test(value);
}

function isAnimeTv(item) {
  return Array.isArray(item.genre_ids) && item.genre_ids.includes(16);
}

function genreNames(ids = [], genres = []) {
  if (Array.isArray(genres) && genres.length > 0) {
    return genres.map((genre) => genre.name).filter(Boolean).filter((name) => name !== '애니메이션');
  }
  return ids.map((id) => GENRES[id]).filter(Boolean).filter((name) => name !== '애니메이션');
}

function isoDate(date) {
  return date.toISOString().slice(0, 10);
}

function parseDateOnly(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return null;
  const [year, month, day] = value.split('-').map(Number);
  return new Date(year, month - 1, day);
}

function koreaToday() {
  const now = new Date();
  return new Date(now.toLocaleString('en-US', {timeZone: 'Asia/Seoul'}));
}

function jikanSeasonsFromYearStart(today) {
  const year = today.getFullYear();
  return ['winter', 'spring', 'summer', 'fall'].map((name) => ({year, name}));
}

function dateOnly(value) {
  return typeof value === 'string' && value.length >= 10 ? value.slice(0, 10) : '';
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
function monthsFromYearStart(today) {
  const months = [];
  const year = today.getFullYear();
  for (let month = 0; month < 12; month += 1) {
    const start = new Date(year, month, 1);
    const end = new Date(year, month + 1, 0);
    months.push({start, end});
  }
  return months;
}

function xml(item, tag) {
  return item.match(new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`))?.[1] || '';
}

function normalizeNewsUrl(url) {
  try {
    const parsed = new URL(url);
    const original = parsed.searchParams.get('url');
    return original ? decode(original) : url;
  } catch (_) {
    return url;
  }
}

function imageMeta(html) {
  const patterns = [
    /<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i,
    /<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i,
    /<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["']/i,
    /<meta[^>]+content=["']([^"']+)["'][^>]+name=["']twitter:image["']/i,
  ];
  for (const pattern of patterns) {
    const value = decode(pattern.exec(html)?.[1] || '');
    if (value.startsWith('https://')) return value;
  }
  return '';
}

function decode(value) {
  return value
    .replace(/<!\[CDATA\[|\]\]>/g, '')
    .replace(/&#(\d+);/g, (_, code) => String.fromCharCode(Number(code)))
    .replace(/&#x([0-9a-f]+);/gi, (_, code) => String.fromCharCode(parseInt(code, 16)))
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .trim();
}

function isRelevantNews(title) {
  return /(애니|극장판|시즌|방영|공개|개봉|흥행|관객|박스오피스|순위)/.test(title) && !/(웹툰|게임|굿즈|리뷰)/.test(title);
}

function hash(value) {
  let result = 0;
  for (let i = 0; i < value.length; i += 1) result = Math.imul(31, result) + value.charCodeAt(i) | 0;
  return Math.abs(result).toString(36);
}

function corsHeaders(extra = {}) {
  return {
    ...extra,
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type',
  };
}

function cors() {
  return new Response(null, {status: 204, headers: corsHeaders()});
}
function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders({'content-type': 'application/json; charset=utf-8'}),
  });
}










