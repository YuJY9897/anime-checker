const TMDB = 'https://api.themoviedb.org/3';
const IMAGE = 'https://image.tmdb.org/t/p/w500';

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    try {
      if (url.pathname === '/search') return json(await searchAnime(env, url.searchParams.get('q') || ''));
      if (url.pathname.startsWith('/anime/')) return json(await animeDetail(env, url.pathname.split('/').pop()));
      if (url.pathname === '/new-anime') return json({items: await newAnime(env, url.searchParams.get('region') || 'KR')});
      if (url.pathname === '/news') return json({items: await news()});
      if (url.pathname === '/image') return proxyImage(url.searchParams.get('url') || '');
      return json({error: 'not found'}, 404);
    } catch (error) {
      return json({error: String(error?.message || error)}, 500);
    }
  },
};

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
  const results = (data.results || []).filter((item) => item.original_language === 'ja' || hasKorean(item.name));
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

async function newAnime(env, region) {
  const today = new Date();
  const past = new Date(today);
  past.setMonth(past.getMonth() - 4);
  const future = new Date(today);
  future.setMonth(future.getMonth() + 2);
  const params = new URLSearchParams({
    first_air_date_gte: isoDate(past),
    first_air_date_lte: isoDate(future),
    sort_by: 'first_air_date.desc',
    with_original_language: 'ja',
    watch_region: region,
    with_watch_monetization_types: 'flatrate|ads|free',
    page: '1',
  });
  const data = await tmdb(env, `/discover/tv?${params.toString()}`);
  return (data.results || [])
    .filter((item) => item.name && item.first_air_date)
    .slice(0, 30)
    .map(toAnime);
}

async function news() {
  const query = encodeURIComponent('애니 신작 OR 애니 시즌 OR 극장판 애니 OR 애니 흥행');
  const response = await fetch(`https://news.google.com/rss/search?q=${query}&hl=ko&gl=KR&ceid=KR:ko`);
  if (!response.ok) throw new Error(`NEWS ${response.status}`);
  const text = await response.text();
  return [...text.matchAll(/<item>([\s\S]*?)<\/item>/g)].slice(0, 20).map((match, index) => {
    const item = match[1];
    const title = decode(xml(item, 'title')).replace(/ - .*$/, '');
    const source = decode(xml(item, 'source'));
    const url = decode(xml(item, 'link'));
    const date = new Date(decode(xml(item, 'pubDate')) || Date.now()).toISOString();
    return {
      id: `news-${index}-${hash(url)}`,
      title,
      summary: title,
      source,
      date,
      imageUrl: '',
      url,
    };
  }).filter((item) => isRelevantNews(item.title));
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
    id: String(item.id),
    title: item.name || item.title || '',
    originalTitle: item.original_name || item.original_title || '',
    posterUrl: poster(item.poster_path),
    genres: [],
    status: item.status || '',
    weekday: '',
    firstAirDate: item.first_air_date || '',
    seasons: [],
    movies: [],
    dropped: false,
  };
}

function poster(path) {
  return path ? `${IMAGE}${path}` : '';
}

function hasKorean(value = '') {
  return /[가-힣]/.test(value);
}

function isoDate(date) {
  return date.toISOString().slice(0, 10);
}

function xml(item, tag) {
  return item.match(new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`))?.[1] || '';
}

function decode(value) {
  return value.replace(/<!\[CDATA\[|\]\]>/g, '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').trim();
}

function isRelevantNews(title) {
  return /(애니|극장판|시즌|방영|공개|개봉|흥행|관객|박스오피스|순위)/.test(title) && !/(웹툰|게임|굿즈|리뷰)/.test(title);
}

function hash(value) {
  let result = 0;
  for (let i = 0; i < value.length; i += 1) result = Math.imul(31, result) + value.charCodeAt(i) | 0;
  return Math.abs(result).toString(36);
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {'content-type': 'application/json; charset=utf-8', 'access-control-allow-origin': '*'},
  });
}
