const TMDB = 'https://api.themoviedb.org/3';
const IMAGE = 'https://image.tmdb.org/t/p/w500';
const GENRES = {
  16: '애니메이션',
  35: '코미디',
  18: '드라마',
  10759: '액션/모험',
  10765: 'SF/판타지',
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
  const tv = await tmdb(env, `/tv/${id}?append_to_response=season/1`);
  const seasons = (tv.seasons || [])
    .filter((season) => season.season_number > 0 && season.episode_count > 0)
    .map((season) => ({
      number: season.season_number,
      name: season.name || `${season.season_number}기`,
      subtitle: '',
      posterUrl: poster(season.poster_path || tv.poster_path),
      episodes: Array.from({length: season.episode_count}, (_, index) => ({
        number: index + 1,
        title: `${index + 1}화`,
        airDate: '',
      })),
    }));
  return {
    ...toAnime(tv),
    seasons,
    movies: [],
  };
}

async function newAnime(env, region, until) {
  const today = parseDateOnly(until) || koreaToday();
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
    .slice(0, 160)
    .map(toAnime);
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
  for (let page = 1; page <= 2; page += 1) {
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
  for (let page = 1; page <= 2; page += 1) {
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
      if (request.method === 'OPTIONS') return cors();
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
      if (request.method === 'OPTIONS') return cors();
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
  return item.first_air_date || item.release_date || '';
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
    return genres.map((genre) => genre.name).filter(Boolean);
  }
  return ids.map((id) => GENRES[id]).filter(Boolean);
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
      if (request.method === 'OPTIONS') return cors();
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