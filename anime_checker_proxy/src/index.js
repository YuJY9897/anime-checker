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
  const anime = toAnimeFromJikan(item);
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
  const episodes = Array.from({length: episodeCount}, (_, index) => ({
    number: index + 1,
    title: `${index + 1}화`,
    airDate: '',
  }));
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
  const [jikanItems, tmdbItems] = await Promise.all([
    jikanNewAnime(env, today).catch(() => []),
    tmdbNewAnime(env, region, today).catch(() => []),
  ]);
  const sortedItems = mergeAnimeItems([...jikanItems, ...tmdbItems])
    .sort((a, b) => releaseSort(a, b, today))
    .slice(0, 300);
  const enrichedItems = await enrichRecentJikanTitles(env, sortedItems);
  return dedupeAnimeItemsByTitle(enrichedItems)
    .sort((a, b) => releaseSort(a, b, today))
    .slice(0, 300);
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
    .filter((item) => item.firstAirDate)
    .sort((a, b) => animeItemDate(b).localeCompare(animeItemDate(a)));
  return items;
}

async function enrichRecentJikanTitles(env, items) {
  const results = [...items];
  const limit = Math.min(48, results.length);
  const batchSize = 6;
  for (let start = 0; start < limit; start += batchSize) {
    const batch = results.slice(start, start + batchSize);
    const enriched = await Promise.all(batch.map((item) => enrichJikanTitle(env, item)));
    for (let index = 0; index < enriched.length; index += 1) {
      results[start + index] = enriched[index];
    }
  }
  return results;
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
  for (const item of items) {
    const titleKey = normalizeTitle(animeItemTitle(item));
    const index = merged.findIndex((current) => isSameTitle(titleKey, normalizeTitle(animeItemTitle(current))));
    if (index < 0) {
      merged.push(item);
    } else if (animeCompleteness(item) > animeCompleteness(merged[index])) {
      merged[index] = item;
    }
  }
  return merged;
}

function isSameTitle(a, b) {
  if (!a || !b) return false;
  if (a === b) return true;
  if (a.length < 8 || b.length < 8) return false;
  return a.startsWith(b) || b.startsWith(a);
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
  const allowedTypes = new Set(['TV', 'ONA', 'OVA', 'Movie', 'Special', 'TV Special']);
  return allowedTypes.has(item.type) && !isClearlyNonJapaneseJikan(item);
}

function isClearlyNonJapaneseJikan(item) {
  if (/[가-힣]/.test(item.title_japanese || '')) return true;
  const names = [
    ...(item.studios || []),
    ...(item.producers || []),
    ...(item.licensors || []),
  ].map((entry) => entry.name || '').join(' ');
  return /(Tencent|bilibili|iQIYI|Youku|China Literature|Yuewen|Fanqie|B\.CMAY|Thundray|Sparkly Key|Wonder Cat|Original Force|Shenman|Yien Animation|Flying Fish|Guangzhou|Haoliners|Motion Magic|Colored Pencil|PB Animation|ASK Animation)/i.test(names);
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
  const month = today.getMonth() + 1;
  const seasons = [{year, name: 'winter'}];
  if (month >= 4) seasons.push({year, name: 'spring'});
  if (month >= 7) seasons.push({year, name: 'summer'});
  if (month >= 10) seasons.push({year, name: 'fall'});
  return seasons;
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
  for (let month = 0; month <= today.getMonth(); month += 1) {
    const start = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const end = month === today.getMonth() ? today : lastDay;
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

