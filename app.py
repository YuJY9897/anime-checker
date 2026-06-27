import json
import hashlib
import html
import re
from pathlib import Path

import streamlit as st
import streamlit.components.v1 as components
import requests
from datetime import datetime, timedelta
from anime_checker.back_handler import PARENT_BACK_HANDLER_JS
from anime_checker.menu_library import build_tile_cards, render_anime_tile_grid
from anime_checker.menu_new_anime import render_new_anime_menu
from anime_checker.menu_news import render_news_menu
from anime_checker.menu_wish import render_wish_menu
from anime_checker.news import get_anime_news
from anime_checker.storage import (
    build_app_data,
    build_backup_json_text,
    load_app_data_file,
    parse_app_data_json,
    save_app_data_file,
)
from anime_checker.ui_assets import APP_CSS, SCROLL_TOP_LINK

try:
    from streamlit_local_storage import LocalStorage
except Exception:
    LocalStorage = None

# === 1. API 및 장르 설정 ===
try:
    TMDB_API_KEY = st.secrets.get("TMDB_API_KEY", "")
except Exception:
    TMDB_API_KEY = ""

TMDB_GENRE_MAP = {
    10759: "액션/판타지", 16: "애니메이션", 35: "코미디", 18: "드라마",
    10751: "가족", 10762: "키즈", 9648: "미스터리", 10765: "SF/판타지",
    80: "범죄", 10768: "전쟁/정치", 37: "서부", 99: "다큐멘터리"
}

st.set_page_config(page_title="애니 업데이트 체크", layout="centered")

if not TMDB_API_KEY:
    st.warning("TMDB API 키가 없어 데모 데이터로 실행됩니다. 실제 검색을 쓰려면 secrets에 TMDB_API_KEY를 설정하세요.")

st.markdown("<div id='top'></div>", unsafe_allow_html=True)

APP_DIR = Path(__file__).resolve().parent
DATA_FILE = APP_DIR / "anime_check_data.json"
BROWSER_STORAGE_KEY = "anime_checker_data_v1"


def load_app_data():
    return load_app_data_file(DATA_FILE)


def save_app_data():
    data = build_app_data(
        st.session_state.get("my_anime_list", {}),
        st.session_state.get("watched_db", {}),
        st.session_state.get("wish_list", {}),
    )
    save_app_data_file(DATA_FILE, data)
    st.session_state.pending_local_save = True
    st.session_state.local_save_version = st.session_state.get("local_save_version", 0) + 1


def build_backup_json():
    data = build_app_data(
        st.session_state.get("my_anime_list", {}),
        st.session_state.get("watched_db", {}),
        st.session_state.get("wish_list", {}),
    )
    return build_backup_json_text(data)


def summarize_backup_data(data):
    anime_list = data.get("my_anime_list", {})
    watched_db = data.get("watched_db", {})
    wish_list = data.get("wish_list", {})
    dropped_count = sum(1 for info in anime_list.values() if isinstance(info, dict) and info.get("dropped"))
    watched_count = sum(1 for watched in watched_db.values() if watched)
    return {
        "anime_count": len(anime_list),
        "dropped_count": dropped_count,
        "wish_count": len(wish_list),
        "watched_count": watched_count,
    }


def restore_backup_file(uploaded_file):
    data = parse_app_data_json(uploaded_file.getvalue())
    if data is None:
        return False, "백업 파일 형식이 맞지 않습니다."

    st.session_state.my_anime_list = data["my_anime_list"]
    st.session_state.watched_db = data["watched_db"]
    st.session_state.wish_list = data.get("wish_list", {})
    st.session_state.selected_anime = None
    st.session_state.selected_season = None
    st.session_state.view = "main"
    save_app_data()
    return True, "백업을 불러왔습니다."


def restore_backup_text(raw_text):
    data = parse_app_data_json(raw_text)
    if data is None:
        return False, "붙여넣은 백업 내용이 올바르지 않습니다."

    st.session_state.my_anime_list = data["my_anime_list"]
    st.session_state.watched_db = data["watched_db"]
    st.session_state.wish_list = data.get("wish_list", {})
    st.session_state.selected_anime = None
    st.session_state.selected_season = None
    st.session_state.view = "main"
    save_app_data()
    return True, "백업을 불러왔습니다."


def inject_browser_script(script):
    components.html(
        f"""
        <script>
        (function () {{
            const code = {json.dumps(script)};
            const targets = [window.parent, window.top, window];
            for (const target of targets) {{
                try {{
                    if (target && target.eval) {{
                        target.eval(code);
                    }}
                }} catch (error) {{}}
            }}
        }})();
        </script>
        """,
        height=1,
    )


st.markdown(APP_CSS, unsafe_allow_html=True)

st.markdown(SCROLL_TOP_LINK, unsafe_allow_html=True)

inject_browser_script(PARENT_BACK_HANDLER_JS)


# === 2. 외부 API 통신 함수 ===

def tmdb_get(endpoint, params=None):
    if not TMDB_API_KEY:
        return {}

    url = f"https://api.themoviedb.org/3/{endpoint.lstrip('/')}"
    request_params = {"api_key": TMDB_API_KEY, "language": "ko-KR"}
    if params:
        request_params.update(params)

    try:
        res = requests.get(url, params=request_params, timeout=1.5)
        res.raise_for_status()
        return res.json()
    except (requests.RequestException, ValueError):
        return {}


def get_weekday_names(date_text):
    if not date_text:
        return "None", ""
    try:
        dt = datetime.strptime(date_text, "%Y-%m-%d")
    except ValueError:
        return "None", ""
    days_en = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    days_kr = ["월요일", "화요일", "수요일", "목요일", "금요일", "토요일", "일요일"]
    return days_en[dt.weekday()], days_kr[dt.weekday()]


def parse_episode_date(date_text):
    normalized = (date_text or "").replace(".", "-")
    if not normalized or normalized == "9999-12-31":
        return None
    try:
        return datetime.strptime(normalized, "%Y-%m-%d")
    except ValueError:
        return None


def infer_status_from_episodes(seasons, fallback_day="None", fallback_status="정보 없음"):
    episode_dates = []
    future_dates = []
    today = datetime.now().date()

    for season in seasons or []:
        for ep in season.get("episodes", []):
            dt = parse_episode_date(ep.get("date", ""))
            if not dt:
                continue
            episode_dates.append(dt)
            if dt.date() > today:
                future_dates.append(dt)

    if future_dates:
        next_dt = min(future_dates)
        day_en, day_kr = get_weekday_names(next_dt.strftime("%Y-%m-%d"))
        return day_en, f"매주 {day_kr} 방영" if day_kr else "방영 중"

    if episode_dates:
        return "Ended", "방영 종료"

    return fallback_day, fallback_status


def normalize_season_meta(raw_season, season_num):
    season_name = f"{season_num}기"
    tmdb_name = (raw_season.get('name') or '').strip()
    overview = (raw_season.get('overview') or '').strip()

    generic_patterns = [
        rf"^{season_num}기$",
        rf"^시즌\s*{season_num}$",
        rf"^season\s*{season_num}$",
        r"^스페셜$",
        r"^specials?$",
    ]
    is_generic_name = any(re.search(pattern, tmdb_name, re.IGNORECASE) for pattern in generic_patterns)

    if tmdb_name and not is_generic_name:
        subtitle = re.sub(rf"^(시즌\s*{season_num}|season\s*{season_num}|{season_num}기)\s*[:：-]?\s*", "", tmdb_name, flags=re.IGNORECASE).strip()
    else:
        subtitle = overview[:30]
        if len(overview) > 30:
            subtitle += "..."

    return season_name, subtitle


def normalize_episode_title(raw_title, season_num, episode_num):
    title = (raw_title or '').strip()
    if not title:
        return ""

    number_only_patterns = [
        r"^\d+\s*화$",
        r"^제\s*\d+\s*화$",
        r"^episode\s*\d+$",
        r"^ep\.?\s*\d+$",
        rf"^{season_num}기\s*{episode_num}\s*화$",
    ]
    if any(re.search(pattern, title, re.IGNORECASE) for pattern in number_only_patterns):
        return ""
    return title


@st.cache_data(ttl=86400, show_spinner=False)
def get_jikan_anime_poster(query):
    try:
        res = requests.get(
            "https://api.jikan.moe/v4/anime",
            params={"q": query, "limit": 1},
            timeout=1.5,
        )
        res.raise_for_status()
        results = res.json().get("data", [])
        if not results:
            return ""
        images = results[0].get("images", {}).get("jpg", {})
        return images.get("large_image_url") or images.get("image_url") or ""
    except (requests.RequestException, ValueError, KeyError):
        return ""


SEASON_SPLIT_RULES = [
    {
        "keywords": ["주술회전", "呪術廻戦", "jujutsu kaisen"],
        "ranges": [
            {"s_num": 1, "start": 1, "end": 24, "name": "1기", "subtitle": "", "jikan_query": "Jujutsu Kaisen"},
            {"s_num": 2, "start": 25, "end": 47, "name": "2기", "subtitle": "회옥·옥절 / 시부야 사변", "jikan_query": "Jujutsu Kaisen 2nd Season"},
            {"s_num": 3, "start": 48, "end": 999, "name": "3기", "subtitle": "사멸회유", "jikan_query": "Jujutsu Kaisen Culling Game"},
        ],
    },
    {
        "keywords": ["지옥락", "地獄楽", "hell's paradise", "hells paradise", "jigokuraku"],
        "ranges": [
            {"s_num": 1, "start": 1, "end": 13, "name": "1기", "subtitle": "", "jikan_query": "Jigokuraku"},
            {"s_num": 2, "start": 14, "end": 999, "name": "2기", "subtitle": "", "jikan_query": "Jigokuraku 2nd Season"},
        ],
    }
]


def get_default_split_ranges(title):
    title_lower = (title or "").lower()
    for rule in SEASON_SPLIT_RULES:
        if any(keyword.lower() in title_lower for keyword in rule["keywords"]):
            return rule["ranges"]
    return []


def build_watch_key_from_uid(anime_uid, season_num, ep_idx):
    return f"chk_{anime_uid}_s{season_num}_e{ep_idx}"


def get_split_season_image(range_info, fallback_img):
    poster = get_jikan_anime_poster(range_info.get("jikan_query", ""))
    return poster or range_info.get("img") or fallback_img


def build_gap_split_ranges(source_season, gap_days=120):
    episodes = source_season.get("episodes", [])
    if len(episodes) < 8:
        return []

    ranges = []
    season_start = 1
    previous_date = None

    for absolute_ep_idx, ep in enumerate(episodes, 1):
        current_date = parse_episode_date(ep.get("date", ""))
        if previous_date and current_date:
            gap = (current_date.date() - previous_date.date()).days
            if gap >= gap_days and absolute_ep_idx - season_start >= 6:
                ranges.append({
                    "s_num": len(ranges) + 1,
                    "start": season_start,
                    "end": absolute_ep_idx - 1,
                    "name": f"{len(ranges) + 1}기",
                    "subtitle": "",
                })
                season_start = absolute_ep_idx
        if current_date:
            previous_date = current_date

    if not ranges:
        return []

    if len(episodes) - season_start + 1 < 3:
        return []

    ranges.append({
        "s_num": len(ranges) + 1,
        "start": season_start,
        "end": len(episodes),
        "name": f"{len(ranges) + 1}기",
        "subtitle": "",
    })
    return ranges


def get_auto_split_ranges(info):
    seasons = info.get("seasons", [])
    if len(seasons) != 1:
        return []
    return build_gap_split_ranges(seasons[0])


def is_placeholder_season(season):
    episodes = season.get("episodes", [])
    if not episodes:
        return True
    return all(ep.get("date") == "9999.12.31" for ep in episodes)


def remove_empty_seasons(info):
    seasons = info.get("seasons", [])
    filtered = [season for season in seasons if not is_placeholder_season(season)]
    if len(filtered) == len(seasons):
        return False
    for idx, season in enumerate(filtered, 1):
        season["s_num"] = idx
        season["name"] = f"{idx}기"
    info["seasons"] = filtered
    return True


def is_generic_anime_image(image_url):
    lowered = (image_url or "").lower()
    return (
        not lowered
        or "images.unsplash.com" in lowered
        or "placeholder" in lowered
        or "default" in lowered
        or "dummy" in lowered
        or "noimage" in lowered
    )


def refresh_generic_season_images(info):
    if not TMDB_API_KEY or not info.get("tmdb_id"):
        return False

    changed = False
    series_img = info.get("poster_img", "")
    if is_generic_anime_image(series_img):
        detail = tmdb_get(f"tv/{info.get('tmdb_id')}")
        if detail.get("poster_path"):
            series_img = f"https://image.tmdb.org/t/p/w500{detail.get('poster_path')}"
            info["poster_img"] = series_img
            changed = True

    if is_generic_anime_image(series_img):
        return changed

    for season in info.get("seasons", []):
        if not is_generic_anime_image(season.get("img", "")):
            continue
        season_num = season.get("s_num")
        season_detail = tmdb_get(f"tv/{info.get('tmdb_id')}/season/{season_num}") if season_num else {}
        if season_detail.get("poster_path"):
            season["img"] = f"https://image.tmdb.org/t/p/w500{season_detail.get('poster_path')}"
        else:
            season["img"] = series_img
        changed = True

    return changed


def split_continuous_season(source_season, ranges):
    source_episodes = source_season.get("episodes", [])
    source_img = source_season.get("img")
    split_seasons = []
    mapping = []

    for range_info in ranges:
        season_num = range_info["s_num"]
        start_ep = range_info["start"]
        end_ep = range_info["end"]
        selected = []

        for absolute_ep_idx, ep in enumerate(source_episodes, 1):
            if start_ep <= absolute_ep_idx <= end_ep:
                local_ep_idx = absolute_ep_idx - start_ep + 1
                new_ep = dict(ep)
                new_ep["absolute_ep_num"] = absolute_ep_idx
                new_ep["ep_num"] = local_ep_idx
                new_ep["title"] = normalize_episode_title(new_ep.get("title", ""), season_num, local_ep_idx)
                selected.append(new_ep)
                mapping.append({
                    "old_season_num": source_season.get("s_num", 1),
                    "old_season_name": source_season.get("name", "1기"),
                    "old_ep_idx": absolute_ep_idx,
                    "new_season_num": season_num,
                    "new_ep_idx": local_ep_idx,
                })

        if selected:
            split_seasons.append({
                "s_num": season_num,
                "name": range_info.get("name") or f"{season_num}기",
                "subtitle": range_info.get("subtitle", ""),
                "img": get_split_season_image(range_info, source_img),
                "episodes": selected,
            })

    return split_seasons, mapping


def refresh_split_season_images(info, ranges):
    changed = False
    ranges_by_season = {range_info["s_num"]: range_info for range_info in ranges}
    for season in info.get("seasons", []):
        range_info = ranges_by_season.get(season.get("s_num"))
        if not range_info:
            continue
        new_img = get_split_season_image(range_info, season.get("img"))
        if new_img and new_img != season.get("img"):
            season["img"] = new_img
            changed = True
    return changed


def migrate_split_watched_keys(title, info, mapping):
    anime_uid = str(info.get("tmdb_id") or info.get("id") or title)
    for item in mapping:
        old_candidates = [
            build_watch_key_from_uid(anime_uid, item["old_season_num"], item["old_ep_idx"]),
            f"chk_{title}_{item['old_season_name']}_{item['old_ep_idx']}",
        ]
        if any(st.session_state.watched_db.get(key, False) for key in old_candidates):
            new_key = build_watch_key_from_uid(anime_uid, item["new_season_num"], item["new_ep_idx"])
            st.session_state.watched_db[new_key] = True


def split_anime_info(title, info, ranges, migrate_watched=False):
    seasons = info.get("seasons", [])
    if len(seasons) != 1:
        return False

    source_episode_count = len(seasons[0].get("episodes", []))
    if source_episode_count < 2:
        return False

    split_seasons, mapping = split_continuous_season(seasons[0], ranges)
    if len(split_seasons) <= 1:
        return False

    covered_count = sum(len(season.get("episodes", [])) for season in split_seasons)
    if covered_count < source_episode_count:
        return False

    if migrate_watched:
        migrate_split_watched_keys(title, info, mapping)
    info["seasons"] = split_seasons
    info["season_split_applied"] = True
    refresh_split_season_images(info, ranges)
    return True


def apply_season_split_rules(title, info):
    ranges = get_default_split_ranges(title)
    if not ranges:
        ranges = get_auto_split_ranges(info)
    if ranges:
        if not split_anime_info(title, info, ranges, migrate_watched=False):
            if get_default_split_ranges(title):
                refresh_split_season_images(info, ranges)
    return info


@st.cache_data(ttl=3600, show_spinner=False)
def search_anime_api(query):
    if not TMDB_API_KEY:
        if query:
            return [{"id": 99999, "name": f"{query} (API 연동 테스트)", "poster_path": "", "first_air_date": "2024-01-01", "genre_ids": [16]}]
        return []

    search_queries = [query]
    compact_query = compact_title(query)
    exact_tv_ids = []
    if "제로" in compact_query and "이세계" in compact_query:
        exact_tv_ids.append(65942)
        search_queries.extend([
            "Re:ZERO -Starting Life in Another World-",
            "Re:ゼロから始める異世界生活",
        ])

    results = []
    seen_ids = set()
    for tv_id in exact_tv_ids:
        detail = tmdb_get(f"tv/{tv_id}")
        if not detail:
            continue
        seen_ids.add(tv_id)
        results.append({
            "id": tv_id,
            "name": detail.get("name") or detail.get("original_name") or query,
            "original_name": detail.get("original_name", ""),
            "poster_path": detail.get("poster_path", ""),
            "first_air_date": detail.get("first_air_date", ""),
            "genre_ids": [genre.get("id") for genre in detail.get("genres", []) if genre.get("id")],
            "original_language": detail.get("original_language", "ja"),
            "popularity": detail.get("popularity", 0),
        })

    for search_query in dict.fromkeys(q for q in search_queries if q):
        res = tmdb_get("search/tv", {"query": search_query})
        for item in res.get('results', []):
            tv_id = item.get("id")
            if tv_id in seen_ids:
                continue
            if 16 not in item.get('genre_ids', []) or item.get('original_language') != 'ja':
                continue
            seen_ids.add(tv_id)
            results.append(item)

    def score_item(item):
        name_text = compact_title(f"{item.get('name', '')} {item.get('original_name', '')}")
        score = 0
        if compact_query and compact_query in name_text:
            score += 100
        if "rezero" in name_text or "rezero" in compact_query:
            score += 80
        if "제로" in compact_query and "이세계" in compact_query and "rezero" in name_text:
            score += 120
        if item.get("poster_path"):
            score += 10
        return (score, item.get("popularity", 0), item.get("first_air_date") or "")

    results.sort(key=score_item, reverse=True)
    return results


def compact_title(text):
    text = (text or "").lower()
    text = re.sub(r"\([^)]*\)|\[[^\]]*\]", " ", text)
    text = re.sub(r"(시즌|season)\s*\d+|第?\s*\d+\s*(期|季)|\d+\s*기", " ", text, flags=re.IGNORECASE)
    return re.sub(r"[^0-9a-z가-힣ぁ-んァ-ン一-龥]+", "", text)


def is_related_anime_movie(movie, title_candidates):
    if movie.get("original_language") not in {"ja", "ko"}:
        return False
    if 16 not in movie.get("genre_ids", []):
        return False

    movie_text = compact_title(f"{movie.get('title', '')} {movie.get('original_title', '')}")
    if not movie_text:
        return False

    for candidate in title_candidates:
        compact_candidate = compact_title(candidate)
        if len(compact_candidate) >= 3 and (compact_candidate in movie_text or movie_text in compact_candidate):
            return True
    return False


@st.cache_data(ttl=3600, show_spinner=False)
def get_movie_runtime_api(movie_id):
    if not TMDB_API_KEY or not movie_id:
        return 0
    movie_detail = tmdb_get(f"movie/{movie_id}")
    return movie_detail.get("runtime") or 0


def format_runtime(minutes):
    try:
        minutes = int(minutes or 0)
    except (TypeError, ValueError):
        minutes = 0
    if minutes <= 0:
        return "시간 정보 없음"
    hours, mins = divmod(minutes, 60)
    if hours and mins:
        return f"{hours}시간 {mins}분"
    if hours:
        return f"{hours}시간"
    return f"{mins}분"


def sort_date_value(date_text):
    date_text = (date_text or "").replace(".", "-")
    if not date_text or date_text.startswith("9999") or "정보 없음" in date_text:
        return "9999-99-99"
    return date_text


def get_season_sort_date(season):
    dates = [
        sort_date_value(ep.get("date", ""))
        for ep in season.get("episodes", [])
        if sort_date_value(ep.get("date", "")) != "9999-99-99"
    ]
    return min(dates) if dates else "9999-99-99"


@st.cache_data(ttl=3600, show_spinner=False)
def get_related_anime_movies_api(title, original_title=""):
    if not TMDB_API_KEY:
        return [{
            "id": 0,
            "title": f"{title} 극장판",
            "release_date": "2024.01.01",
            "runtime": 105,
            "img": "",
        }]

    title_candidates = [title, original_title]
    search_queries = [candidate for candidate in title_candidates if candidate]
    collected = []
    seen_ids = set()

    for query in dict.fromkeys(search_queries):
        res = tmdb_get("search/movie", {"query": query, "include_adult": "false"})
        for movie in res.get("results", []):
            movie_id = movie.get("id")
            if not movie_id or movie_id in seen_ids:
                continue
            if not is_related_anime_movie(movie, title_candidates):
                continue
            seen_ids.add(movie_id)
            movie_title = movie.get("title") or movie.get("original_title") or "제목 없음"
            release_date = (movie.get("release_date") or "").replace("-", ".")
            runtime = get_movie_runtime_api(movie_id)
            collected.append({
                "id": movie_id,
                "title": movie_title,
                "original_title": movie.get("original_title", ""),
                "release_date": release_date or "개봉일 정보 없음",
                "runtime": runtime,
                "img": f"https://image.tmdb.org/t/p/w500{movie.get('poster_path')}" if movie.get("poster_path") else "",
            })

    collected.sort(key=lambda movie: movie.get("release_date", "9999.99.99"))
    return collected[:8]


@st.cache_data(ttl=3600, show_spinner=False)
def get_anime_details_api(tv_id, title):
    if not TMDB_API_KEY:
        return {
            "tmdb_id": tv_id,
            "title": title,
            "day": "Monday",
            "display_status": "API 연동 대기중",
            "start_date": "2024.01.01",
            "genre": "애니메이션",
            "related_movies": get_related_anime_movies_api(title),
            "seasons": [{
                "s_num": 1, "name": "1기", "subtitle": "API 자동 불러오기 테스트",
                "img": "",
                "episodes": [{"title": "1화", "date": "2024.01.01"}]
            }]
        }

    res = tmdb_get(f"tv/{tv_id}")
    if not res:
        return {
            "tmdb_id": tv_id,
            "title": title,
            "day": "None",
            "display_status": "상세 정보 불러오기 실패",
            "start_date": "",
            "genre": "",
            "related_movies": [],
            "seasons": []
        }

    genres = " / ".join([g.get('name', '') for g in res.get('genres', []) if g.get('name')])
    original_title = res.get('original_name', '')
    series_img = f"https://image.tmdb.org/t/p/w500{res.get('poster_path')}" if res.get('poster_path') else ""
    start_date_raw = res.get('first_air_date', '')
    start_date = start_date_raw.replace('-', '.')
    status_raw = res.get('status', '')
    next_air_date = (res.get('next_episode_to_air') or {}).get('air_date')
    last_air_date = (res.get('last_episode_to_air') or {}).get('air_date')
    schedule_date = next_air_date or last_air_date or start_date_raw

    day_en, day_kr = get_weekday_names(schedule_date)
    if status_raw in ['Ended', 'Canceled']:
        display_status = "방영 종료"
        day_en = "Ended"
    elif next_air_date:
        display_status = f"다음 화 {next_air_date.replace('-', '.')} ({day_kr})" if day_kr else "방영 중"
    elif status_raw in ['Returning Series', 'In Production']:
        display_status = f"매주 {day_kr} 방영" if day_kr else "방영 중"
    else:
        display_status = "방영 예정"

    seasons_data = []
    for s in res.get('seasons', []):
        s_num = s.get('season_number')
        if s_num == 0 or s_num is None:
            continue

        s_name, subtitle = normalize_season_meta(s, s_num)

        s_img = f"https://image.tmdb.org/t/p/w500{s.get('poster_path')}" if s.get('poster_path') else series_img
        ep_res = tmdb_get(f"tv/{tv_id}/season/{s_num}")

        episodes = []
        for local_ep_idx, ep in enumerate(ep_res.get('episodes', []), 1):
            ep_date = ep.get('air_date')
            ep_num = ep.get('episode_number') or local_ep_idx
            episodes.append({
                "ep_num": local_ep_idx,
                "tmdb_ep_num": ep_num,
                "title": normalize_episode_title(ep.get('name'), s_num, local_ep_idx),
                "date": ep_date.replace('-', '.') if ep_date else "9999.12.31"
            })

        if not episodes or all(ep.get("date") == "9999.12.31" for ep in episodes):
            continue

        seasons_data.append({
            "s_num": s_num,
            "name": s_name,
            "subtitle": subtitle,
            "img": s_img,
            "episodes": episodes
        })

    day_en, display_status = infer_status_from_episodes(seasons_data, day_en, display_status)

    anime_info = {
        "tmdb_id": tv_id,
        "title": title,
        "day": day_en,
        "display_status": display_status,
        "start_date": start_date,
        "genre": genres,
        "original_title": original_title,
        "poster_img": series_img,
        "related_movies": get_related_anime_movies_api(title, original_title),
        "seasons": seasons_data
    }
    return apply_season_split_rules(title, anime_info)


def has_korean_title(item):
    return bool(re.search(r"[가-힣]", item.get("name", "")))


@st.cache_data(ttl=3600, show_spinner=False)
def get_trending_anime_api(page=1, ott_only=True):
    if not TMDB_API_KEY:
        if page != 1 or not ott_only:
            return []
        return [
            {"id": "demo_recent_1", "name": "최근 핫한 애니 1", "poster_path": "", "first_air_date": datetime.now().strftime("%Y-%m-%d"), "genre_ids": [16]}
        ]

    recent_date = (datetime.now() - timedelta(days=240)).strftime('%Y-%m-%d')
    future_date = (datetime.now() + timedelta(days=180)).strftime('%Y-%m-%d')
    request_params = {
        "with_genres": 16,
        "with_original_language": "ja",
        "sort_by": "first_air_date.desc",
        "first_air_date.gte": recent_date,
        "first_air_date.lte": future_date,
        "include_null_first_air_dates": "false",
        "page": page,
    }
    if ott_only:
        request_params["watch_region"] = "KR"
        request_params["with_watch_monetization_types"] = "flatrate|free|ads"
    res = tmdb_get("discover/tv", request_params)
    return [item for item in res.get('results', []) if has_korean_title(item)]

# === 3. 세션 상태 관리 및 콜백 함수 ===

if 'view' not in st.session_state: st.session_state.view = 'main'
if 'selected_anime' not in st.session_state: st.session_state.selected_anime = None
if 'selected_season' not in st.session_state: st.session_state.selected_season = None
if 'is_editing' not in st.session_state: st.session_state.is_editing = False
if 'selected_news' not in st.session_state: st.session_state.selected_news = None
if 'search_box' not in st.session_state: st.session_state.search_box = ""
if 'search_input_text' not in st.session_state: st.session_state.search_input_text = st.session_state.search_box
if 'library_filter' not in st.session_state: st.session_state.library_filter = ""
if 'show_library_search' not in st.session_state: st.session_state.show_library_search = False
if 'news_return_view' not in st.session_state: st.session_state.news_return_view = 'main'
if 'main_section' not in st.session_state: st.session_state.main_section = '새 화'
if 'pending_local_save' not in st.session_state: st.session_state.pending_local_save = False
if 'local_save_version' not in st.session_state: st.session_state.local_save_version = 0
if 'loaded_from_local_storage' not in st.session_state: st.session_state.loaded_from_local_storage = False
if 'backup_notice' not in st.session_state: st.session_state.backup_notice = None

local_storage = LocalStorage() if LocalStorage is not None else None
local_storage_raw = None
if local_storage is not None:
    try:
        local_storage_raw = local_storage.getItem(BROWSER_STORAGE_KEY)
    except Exception:
        local_storage_raw = None

if 'data_loaded' not in st.session_state:
    saved_data = load_app_data()
    st.session_state.watched_db = saved_data.get("watched_db", {})
    st.session_state.my_anime_list = saved_data.get("my_anime_list", {})
    st.session_state.wish_list = saved_data.get("wish_list", {})
    st.session_state.loaded_updated_at = saved_data.get("updated_at", "")
    st.session_state.data_loaded = True

if 'watched_db' not in st.session_state:
    st.session_state.watched_db = {}
if 'my_anime_list' not in st.session_state:
    st.session_state.my_anime_list = {}
if 'wish_list' not in st.session_state:
    st.session_state.wish_list = {}

local_storage_data = parse_app_data_json(local_storage_raw)
if local_storage_data and not st.session_state.loaded_from_local_storage:
    has_local_data = bool(local_storage_data["my_anime_list"]) or bool(local_storage_data["watched_db"]) or bool(local_storage_data.get("wish_list", {}))
    current_has_data = bool(st.session_state.my_anime_list) or bool(st.session_state.watched_db) or bool(st.session_state.wish_list)
    if has_local_data and (not current_has_data or local_storage_data.get("updated_at", "") >= st.session_state.get("loaded_updated_at", "")):
        st.session_state.my_anime_list = local_storage_data["my_anime_list"]
        st.session_state.watched_db = local_storage_data["watched_db"]
        st.session_state.wish_list = local_storage_data.get("wish_list", {})
        st.session_state.loaded_from_local_storage = True
        st.session_state.pending_local_save = False
        st.session_state.selected_anime = None
        st.session_state.selected_season = None
        st.session_state.selected_news = None
        st.session_state.view = "main"
        st.rerun()
    st.session_state.loaded_from_local_storage = True

app_back_target = st.query_params.get("app_back")
if app_back_target:
    st.query_params.clear()
    if app_back_target == "season_list":
        if st.session_state.get("selected_anime"):
            st.session_state.view = "detail"
            st.session_state.selected_season = None
        else:
            st.session_state.selected_anime = None
            st.session_state.selected_season = None
            st.session_state.selected_news = None
            st.session_state.view = "main"
            st.session_state.main_section = "새 화"
    elif app_back_target == "detail":
        st.session_state.view = "detail"
        st.session_state.selected_season = None
    elif app_back_target == "news_return":
        st.session_state.selected_news = None
        st.session_state.view = "main"
        st.session_state.news_return_view = "main"
    else:
        st.session_state.selected_anime = None
        st.session_state.selected_season = None
        st.session_state.selected_news = None
        st.session_state.view = "main"
        st.session_state.main_section = "새 화"
    st.rerun()

main_nav_target = st.query_params.get("main_nav")
if main_nav_target:
    del st.query_params["main_nav"]
    st.session_state.main_section = main_nav_target
    st.session_state.show_library_search = False
    st.session_state.library_filter = ""
    st.session_state.selected_anime = None
    st.session_state.selected_season = None
    st.session_state.selected_news = None
    st.session_state.view = "main"
    st.rerun()

# --- 과거 데이터 마이그레이션 (자가 치유 로직) ---
current_date_str = datetime.now().strftime('%Y.%m.%d')
existing_data_changed = False
for title, info in st.session_state.my_anime_list.items():
    if remove_empty_seasons(info):
        existing_data_changed = True
    if refresh_generic_season_images(info):
        existing_data_changed = True

    if info.get('day') == "방영 종료/진행중" or 'display_status' not in info:
        start_date_str = info.get('start_date', '').replace('.', '-')
        day_en = "None"
        day_kr = ""
        if start_date_str:
            try:
                dt = datetime.strptime(start_date_str, "%Y-%m-%d")
                day_en = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][dt.weekday()]
                day_kr = ["월요일", "화요일", "수요일", "목요일", "금요일", "토요일", "일요일"][dt.weekday()]
            except:
                pass
        
        has_future_ep = False
        for s in info.get('seasons', []):
            for ep in s.get('episodes', []):
                if ep['date'] > current_date_str and ep['date'] != "9999.12.31":
                    has_future_ep = True
                    break
        
        if has_future_ep:
            info['day'] = day_en
            info['display_status'] = f"매주 {day_kr} 방영" if day_kr else "방영 중"
        else:
            info['day'] = "Ended"
            info['display_status'] = "방영 종료"

    manual_split_ranges = get_default_split_ranges(title)
    split_ranges = manual_split_ranges or get_auto_split_ranges(info)
    if split_ranges and len(info.get('seasons', [])) == 1:
        if split_anime_info(title, info, split_ranges, migrate_watched=True):
            existing_data_changed = True
    elif manual_split_ranges and refresh_split_season_images(info, manual_split_ranges):
        existing_data_changed = True

    for idx, season in enumerate(info.get('seasons', [])):
        season_num = season.get('s_num') or idx + 1
        old_name = season.get('name', '')
        if season.get('s_num') != season_num:
            season['s_num'] = season_num
            existing_data_changed = True
        if old_name != f"{season_num}기":
            if old_name and not season.get('subtitle'):
                season['subtitle'] = old_name
            season['name'] = f"{season_num}기"
            existing_data_changed = True
        for ep_idx, ep in enumerate(season.get('episodes', []), 1):
            if ep.get('ep_num') != ep_idx:
                ep['ep_num'] = ep_idx
                existing_data_changed = True
            cleaned_title = normalize_episode_title(ep.get('title', ''), season_num, ep_idx)
            if ep.get('title', '') != cleaned_title:
                ep['title'] = cleaned_title
                existing_data_changed = True

    inferred_day, inferred_status = infer_status_from_episodes(
        info.get('seasons', []),
        info.get('day', 'None'),
        info.get('display_status', '정보 없음')
    )
    if info.get('day') != inferred_day or info.get('display_status') != inferred_status:
        info['day'] = inferred_day
        info['display_status'] = inferred_status
        existing_data_changed = True

if existing_data_changed:
    save_app_data()

if local_storage is not None and st.session_state.get("pending_local_save", False):
    try:
        backup_json = build_backup_json()
        local_storage.setItem(
            BROWSER_STORAGE_KEY,
            backup_json,
            key=f"save_browser_storage_{st.session_state.get('local_save_version', 0)}"
        )
        st.session_state.pending_local_save = False
    except Exception:
        pass

backup_notice = st.session_state.pop("backup_notice", None)
if backup_notice:
    notice_type, notice_text = backup_notice
    if notice_type == "success":
        st.success(notice_text)
    else:
        st.error(notice_text)
# --------------------------------------------------------

def get_anime_uid(title, info=None):
    info = info or st.session_state.my_anime_list.get(title, {})
    return str(info.get("tmdb_id") or info.get("id") or title)


def make_watch_key(title, season, ep_idx):
    info = st.session_state.my_anime_list.get(title, {})
    anime_uid = get_anime_uid(title, info)
    season_num = season.get("s_num") or season.get("name", "season")
    return build_watch_key_from_uid(anime_uid, season_num, ep_idx)


def make_movie_watch_key(title, movie):
    info = st.session_state.my_anime_list.get(title, {})
    anime_uid = get_anime_uid(title, info)
    movie_uid = movie.get("id") or compact_title(movie.get("title", "movie"))
    return f"chk_{anime_uid}_movie_{movie_uid}"


def get_watch_value(title, season, ep_idx):
    new_key = make_watch_key(title, season, ep_idx)
    old_key = f"chk_{title}_{season.get('name', '')}_{ep_idx}"
    if new_key in st.session_state.watched_db:
        return st.session_state.watched_db.get(new_key, False)
    if old_key in st.session_state.watched_db:
        st.session_state.watched_db[new_key] = st.session_state.watched_db.pop(old_key)
        save_app_data()
        return st.session_state.watched_db.get(new_key, False)
    return False


def refresh_related_movie_runtime(info):
    changed = False
    for movie in info.get("related_movies", []):
        if movie.get("runtime"):
            continue
        runtime = get_movie_runtime_api(movie.get("id"))
        if runtime:
            movie["runtime"] = runtime
            changed = True
    return changed


def is_generic_image_url(url):
    lowered = (url or "").lower()
    return (
        not lowered
        or "images.unsplash.com" in lowered
        or "placeholder" in lowered
        or "default" in lowered
        or "dummy" in lowered
        or "noimage" in lowered
    )


def get_display_season_image(season, anime_info):
    season_img = season.get("img", "")
    if not is_generic_image_url(season_img):
        return season_img
    for key in ("poster_img", "img", "series_img"):
        candidate = anime_info.get(key, "")
        if not is_generic_image_url(candidate):
            return candidate
    return ""


def add_anime_to_list(tv_id, title):
    st.session_state.my_anime_list[title] = get_anime_details_api(tv_id, title)
    st.session_state.wish_list.pop(str(tv_id), None)
    save_app_data()


def make_wish_item(tv_id, title, item=None):
    item = item or {}
    rep_img = f"https://image.tmdb.org/t/p/w500{item.get('poster_path')}" if item.get('poster_path') else ""
    return {
        "id": tv_id,
        "title": title,
        "poster_path": item.get("poster_path", ""),
        "img": rep_img,
        "first_air_date": item.get("first_air_date", ""),
        "genre_ids": item.get("genre_ids", []),
    }


def toggle_wish(tv_id, title, item=None):
    wish_key = str(tv_id)
    if wish_key in st.session_state.wish_list:
        st.session_state.wish_list.pop(wish_key, None)
    else:
        st.session_state.wish_list[wish_key] = make_wish_item(tv_id, title, item)
    save_app_data()


def is_wished(tv_id):
    return str(tv_id) in st.session_state.wish_list


def is_dropped(info):
    return bool(info.get("dropped", False))


def toggle_dropped(title):
    info = st.session_state.my_anime_list.get(title)
    if not info:
        return
    info["dropped"] = not is_dropped(info)
    save_app_data()


def delete_anime(title):
    info = st.session_state.my_anime_list.get(title, {})
    anime_uid = get_anime_uid(title, info)
    st.session_state.my_anime_list.pop(title, None)

    old_prefix = f"chk_{title}_"
    new_prefix = f"chk_{anime_uid}_"
    for key in list(st.session_state.watched_db.keys()):
        if key.startswith(old_prefix) or key.startswith(new_prefix):
            st.session_state.watched_db.pop(key, None)

    save_app_data()


def on_movie_checkbox_change(a_title, movie, w_key):
    db_key = make_movie_watch_key(a_title, movie)
    st.session_state.watched_db[db_key] = st.session_state.get(w_key, False)
    save_app_data()


def toggle_movie_watch(a_title, movie):
    db_key = make_movie_watch_key(a_title, movie)
    st.session_state.watched_db[db_key] = not st.session_state.watched_db.get(db_key, False)
    save_app_data()


def set_episode_watch(a_title, clicked_s_idx, clicked_ep_idx, is_checked):
    anime_info = st.session_state.my_anime_list[a_title]
    seasons = anime_info.get('seasons', [])

    for s_idx, season in enumerate(seasons):
        for ep_idx, ep in enumerate(season.get('episodes', []), 1):
            db_key = make_watch_key(a_title, season, ep_idx)
            current_w_key = f"widget_{db_key}"

            if is_checked:
                if s_idx < clicked_s_idx or (s_idx == clicked_s_idx and ep_idx <= clicked_ep_idx):
                    st.session_state.watched_db[db_key] = True
                    if current_w_key in st.session_state:
                        st.session_state[current_w_key] = True
            else:
                if s_idx > clicked_s_idx or (s_idx == clicked_s_idx and ep_idx >= clicked_ep_idx):
                    st.session_state.watched_db[db_key] = False
                    if current_w_key in st.session_state:
                        st.session_state[current_w_key] = False

    save_app_data()


def on_checkbox_change(a_title, clicked_s_idx, clicked_ep_idx, w_key):
    set_episode_watch(a_title, clicked_s_idx, clicked_ep_idx, st.session_state[w_key])


def clear_search():
    st.session_state.search_box = ""
    st.session_state.search_input_text = ""

def toggle_library_search():
    st.session_state.show_library_search = not st.session_state.show_library_search
    if not st.session_state.show_library_search:
        st.session_state.library_filter = ""

def add_direct_and_clear(tv_id, title):
    add_anime_to_list(tv_id, title)
    st.session_state.search_box = ""
    st.session_state.search_input_text = ""

def render_article_link(url):
    if not url:
        return
    st.link_button("원문 기사 보기", url, use_container_width=True)


if "news_loaded_at" not in st.session_state:
    st.session_state.news_loaded_at = None
if "news_data" not in st.session_state:
    st.session_state.news_data = []


def ensure_news_loaded(force=False):
    if force or not st.session_state.get("news_data"):
        with st.spinner("애니 소식을 갱신하는 중입니다..."):
            st.session_state.news_data = get_anime_news()
            st.session_state.news_loaded_at = datetime.now()
    return st.session_state.news_data


news_data = st.session_state.news_data
news_loaded_label = (
    st.session_state.news_loaded_at.strftime("%Y.%m.%d %H:%M 기준")
    if st.session_state.news_loaded_at else "갱신 전"
)


def render_news_image(news):
    image_bytes = news.get("img_bytes")
    if image_bytes:
        st.image(image_bytes, use_container_width=True)
        return
    image_url = news.get("img", "")
    if image_url and not is_generic_image_url(image_url):
        st.image(image_url, use_container_width=True)


def get_new_anime_collection():
    raw_new_animes = []
    for page in range(1, 9):
        raw_new_animes.extend(get_trending_anime_api(page=page, ott_only=True))
    for page in range(1, 5):
        raw_new_animes.extend(get_trending_anime_api(page=page, ott_only=False))

    seen_new_ids = set()
    sorted_all_animes = []
    for item in raw_new_animes:
        tv_id = item.get('id') or f"idx_{len(sorted_all_animes)}"
        if tv_id in seen_new_ids:
            continue
        seen_new_ids.add(tv_id)
        sorted_all_animes.append(item)
    sorted_all_animes.sort(key=lambda item: item.get('first_air_date') or "0000-00-00", reverse=True)
    return sorted_all_animes[:30]


def ensure_new_animes_loaded(force=False):
    if force or "new_animes_data" not in st.session_state:
        st.session_state.new_animes_data = get_new_anime_collection()
        st.session_state.new_animes_loaded_at = datetime.now()
    return st.session_state.new_animes_data


def get_loaded_at_label(loaded_at):
    return loaded_at.strftime("%Y.%m.%d. %H:%M 기준") if loaded_at else "갱신 전"


def format_new_anime_air_date(date_text):
    if not date_text:
        return "방영일: 정보 없음"
    display_date = date_text.replace("-", ".")
    try:
        air_date = datetime.strptime(date_text, "%Y-%m-%d").date()
    except ValueError:
        return f"방영일: {display_date}"
    if air_date > datetime.now().date():
        return f"방영일: {display_date}. 방영예정"
    return f"방영일: {display_date}"


def render_new_anime_cards(sorted_all_animes, key_prefix):
    loaded_label = get_loaded_at_label(st.session_state.get("new_animes_loaded_at"))
    render_new_anime_menu(
        sorted_all_animes,
        loaded_label,
        lambda genre_id: TMDB_GENRE_MAP.get(genre_id, ""),
        format_new_anime_air_date,
        is_wished,
        lambda title: title in st.session_state.my_anime_list,
        lambda tv_id, title, item: (toggle_wish(tv_id, title, item), st.rerun()),
        lambda tv_id, title: (add_anime_to_list(tv_id, title), st.rerun()),
    )


def find_anime_title_by_uid(uid):
    uid = str(uid or "")
    for title, info in st.session_state.my_anime_list.items():
        if get_anime_uid(title, info) == uid:
            return title
    return None


def open_anime_detail(title):
    st.session_state.selected_anime = title
    st.session_state.selected_season = None
    st.session_state.selected_news = None
    st.session_state.view = "detail"
    st.rerun()


def open_news_detail(news):
    st.session_state.selected_news = news
    st.session_state.news_return_view = "main"
    st.session_state.view = "news_detail"
    st.rerun()


def render_library_tile_grid(cards, extra_class=""):
    if not cards:
        return
    render_anime_tile_grid(build_tile_cards(cards, get_anime_uid), extra_class, open_anime_detail)


def render_wish_cards(wish_items):
    render_wish_menu(
        wish_items,
        lambda title: title in st.session_state.my_anime_list,
        lambda tv_id, title: (add_anime_to_list(tv_id, title), st.rerun()),
        lambda tv_id: (st.session_state.wish_list.pop(str(tv_id), None), save_app_data(), st.rerun()),
    )


open_anime_uid = st.query_params.get("open_anime")
if open_anime_uid:
    opened_title = find_anime_title_by_uid(open_anime_uid)
    if opened_title:
        del st.query_params["open_anime"]
        st.session_state.selected_anime = opened_title
        st.session_state.selected_season = None
        st.session_state.selected_news = None
        st.session_state.view = "detail"
        st.rerun()
    else:
        del st.query_params["open_anime"]


def render_main_nav(active_label):
    labels = ["새 화", "목록", "보류", "찜", "신작 애니", "애니 소식"]
    if active_label not in labels:
        active_label = "새 화"
    current_label = st.session_state.get("main_section", "새 화")
    selected = st.pills(
        "메인 메뉴",
        labels,
        default=active_label,
        key="main_section_pills",
        label_visibility="collapsed",
        width="stretch",
    )
    if selected and selected != current_label:
        st.session_state.main_section = selected
        st.session_state.show_library_search = False
        st.session_state.library_filter = ""
        st.session_state.selected_anime = None
        st.session_state.selected_season = None
        st.session_state.selected_news = None
        st.session_state.view = "main"
        return selected
    return selected or current_label


def render_app_header():
    today_label = datetime.now().strftime("%Y.%m.%d")
    st.markdown(
        f"""
        <div class="app-shell-header">
            <div>
                <div class="app-brand-kicker">ANIME CHECKER</div>
                <div class="app-brand-title">애니 체크</div>
            </div>
            <div class="app-brand-date">{today_label}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )


current_view_marker = html.escape(str(st.session_state.get("view", "main")), quote=True)
selected_season_marker = "none" if st.session_state.get("selected_season") is None else "selected"
main_section_marker = html.escape(str(st.session_state.get("main_section", "새 화")), quote=True)
st.markdown(
    f"<div id='anime-current-view' data-view='{current_view_marker}' "
    f"data-selected-season='{selected_season_marker}' data-main-section='{main_section_marker}' "
    f"style='display:none;'></div>",
    unsafe_allow_html=True,
)
components.html(
    f"""
    <script>
    window.parent.__animeCheckerCurrentView = {json.dumps({
        "view": st.session_state.get("view", "main"),
        "selectedSeason": selected_season_marker,
        "mainSection": st.session_state.get("main_section", "새 화"),
    }, ensure_ascii=False)};
    </script>
    """,
    height=1,
)
inject_browser_script(PARENT_BACK_HANDLER_JS)

# --- 화면 1: 메인 화면 ---
if st.session_state.view == 'main':
    render_app_header()

    with st.form("anime_search_form"):
        search_col, search_btn_col = st.columns([7, 2], gap="small", vertical_alignment="center")
        with search_col:
            st.text_input("애니메이션 검색", key="search_input_text", placeholder="작품명 검색", label_visibility="collapsed")
        with search_btn_col:
            search_submitted = st.form_submit_button("검색", use_container_width=True)
    if search_submitted:
        st.session_state.search_box = st.session_state.search_input_text.strip()
        st.rerun()
    st.markdown("<div class='search-hint'>작품명을 입력한 뒤 검색 버튼이나 Enter를 누르세요.</div>", unsafe_allow_html=True)
    
    if st.session_state.search_box:
        col1, col2 = st.columns([8, 2])
        with col1:
            st.subheader(f"'{st.session_state.search_box}' 검색 결과")
        with col2:
            st.button("돌아가기", on_click=clear_search)
                
        st.divider()

        search_results = search_anime_api(st.session_state.search_box)
        
        if not search_results:
            st.write("검색 결과가 없습니다.")
        else:
            result_cols = st.columns(2)
            for idx, item in enumerate(search_results):
                title = item['name']
                tv_id = item['id']
                rep_img = f"https://image.tmdb.org/t/p/w500{item['poster_path']}" if item.get('poster_path') else ""
                
                with result_cols[idx % 2]:
                    with st.container(border=True):
                        if rep_img:
                            st.image(rep_img, use_container_width=True)
                        st.markdown(f"<div class='anime-title'>{html.escape(title)}</div>", unsafe_allow_html=True)

                        if title in st.session_state.my_anime_list:
                            st.caption("목록에 있음")
                        else:
                            spacer_col, add_col, wish_col = st.columns([5, 3, 2], gap="small")
                            with spacer_col:
                                st.markdown("<span class='search-actions-anchor'></span>", unsafe_allow_html=True)
                            with add_col:
                                st.button("추가", key=f"add_api_{tv_id}", on_click=add_direct_and_clear, args=(tv_id, title))
                            with wish_col:
                                wish_label = "찜해제" if is_wished(tv_id) else "찜"
                                if st.button(wish_label, key=f"wish_api_{tv_id}"):
                                    toggle_wish(tv_id, title, item)
                                    st.rerun()
            
    else:
        st.divider()

        current_date_str = datetime.now().strftime('%Y.%m.%d')

        def build_library_cards(library_filter=""):
            cards = []
            for title, info in list(st.session_state.my_anime_list.items()):
                if is_dropped(info):
                    continue
                if library_filter and library_filter not in title.lower():
                    continue

                needs_n_badge = False
                latest_aired_ep = None
                latest_aired_date = "0000.00.00"

                for season in info.get('seasons', []):
                    for i, ep in enumerate(season.get('episodes', []), 1):
                        if ep['date'] <= current_date_str:
                            latest_aired_ep = {
                                'season': season,
                                'season_name': season['name'],
                                'ep_num': i
                            }
                            latest_aired_date = ep['date']

                if latest_aired_ep and not get_watch_value(title, latest_aired_ep['season'], latest_aired_ep['ep_num']):
                    needs_n_badge = True

                cards.append({
                    'title': title,
                    'info': info,
                    'needs_n_badge': needs_n_badge,
                    'latest_aired_ep': latest_aired_ep,
                    'latest_aired_date': latest_aired_date,
                })
            return cards

        def render_anime_card_grid(cards, key_prefix):
            render_library_tile_grid(cards, key_prefix)

        def render_library_schedule(key_prefix):
            st.write("")
            st.divider()

            st.subheader("내 보관함 편성표")
            days_en = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            days_kr = ["월", "화", "수", "목", "금", "토", "일"]

            schedule_tabs = st.tabs(days_kr)
            for i, day_en in enumerate(days_en):
                with schedule_tabs[i]:
                    day_animes = {
                        k: v for k, v in st.session_state.my_anime_list.items()
                        if v.get('day') == day_en and not is_dropped(v)
                    }
                    if not day_animes:
                        st.write("해당 요일에 맵핑된 애니가 없습니다.")
                    else:
                        schedule_cards = [
                            {"title": t_name, "info": t_info, "needs_n_badge": False}
                            for t_name, t_info in day_animes.items()
                        ]
                        render_library_tile_grid(schedule_cards, "schedule")

        active_main_tab = st.session_state.get("main_section", "새 화")
        active_main_tab = render_main_nav(active_main_tab)

        if active_main_tab == "새 화":
            st.session_state.is_editing = False
            st.subheader("새 화")

            if not st.session_state.my_anime_list:
                st.write("아직 추가한 애니가 없습니다. 위 검색창에서 작품을 추가해보세요.")
            else:
                library_cards = build_library_cards()
                n_cards = [item for item in library_cards if item['needs_n_badge']]
                n_cards.sort(key=lambda item: item['latest_aired_date'], reverse=True)
                st.markdown(f"<div class='library-count'>총 {len(n_cards)}개</div>", unsafe_allow_html=True)

                if not n_cards:
                    st.write("새로 나온 화가 없습니다.")
                else:
                    render_anime_card_grid(n_cards, "update_card")

                render_library_schedule("update")

        elif active_main_tab == "목록":
            title_col, search_btn_col = st.columns([8, 1], gap="small", vertical_alignment="center")
            with title_col:
                st.markdown("<span class='library-title-actions-anchor'></span>", unsafe_allow_html=True)
                st.subheader("목록")
            with search_btn_col:
                search_btn_label = "닫기" if st.session_state.show_library_search else "검색"
                st.button(search_btn_label, key="toggle_library_search_btn", on_click=toggle_library_search)

            with st.expander("백업 / 불러오기"):
                st.caption("새 화, 목록, 보류, 찜, 시청 기록 전체를 한 번에 저장하고 불러옵니다.")
                backup_col, restore_col = st.columns([1, 1], gap="small")
                with backup_col:
                    st.text_area(
                        "전체 백업 내용",
                        value=build_backup_json(),
                        height=120,
                        key="backup_json_text",
                        help="새 화/목록/보류/찜/시청 기록 전체가 들어 있습니다. 파일 저장이 안 되는 폰에서는 이 내용을 복사해두세요."
                    )
                    st.download_button(
                        "백업 저장",
                        data=build_backup_json(),
                        file_name=f"anime_checker_backup_{datetime.now().strftime('%Y%m%d_%H%M')}.json",
                        mime="application/json",
                        use_container_width=True,
                        key="download_backup_json"
                    )
                with restore_col:
                    backup_file = st.file_uploader(
                        "백업 파일 업로드",
                        type=["json"],
                        key="restore_backup_file"
                    )
                if backup_file is not None:
                    backup_bytes = backup_file.getvalue()
                    backup_hash = hashlib.sha256(backup_bytes).hexdigest()[:12]
                    parsed_backup = parse_app_data_json(backup_bytes)
                    if parsed_backup is None:
                        st.error("업로드한 백업 파일 형식이 맞지 않습니다.")
                    else:
                        backup_summary = summarize_backup_data(parsed_backup)
                        st.success(
                            "백업 파일 확인됨: "
                            f"전체 {backup_summary['anime_count']}개, "
                            f"보류 {backup_summary['dropped_count']}개, "
                            f"찜 {backup_summary['wish_count']}개, "
                            f"시청 기록 {backup_summary['watched_count']}개"
                        )
                        st.caption("적용하면 새 화, 목록, 보류, 찜, 시청 기록 전체가 백업 파일 내용으로 바뀝니다.")
                        if st.button("업로드한 백업 적용", key=f"restore_backup_btn_{backup_hash}", use_container_width=True):
                            ok, message = restore_backup_file(backup_file)
                            if ok:
                                st.session_state.backup_notice = ("success", message)
                                st.rerun()
                            else:
                                st.error(message)
                restore_text = st.text_area(
                    "백업 붙여넣기",
                    value="",
                    height=120,
                    key="restore_backup_text_area",
                    placeholder="백업 내용을 여기에 붙여넣고 아래 버튼을 누르세요."
                )
                if st.button("붙여넣은 백업 불러오기", key="restore_backup_text_btn", use_container_width=True):
                    ok, message = restore_backup_text(restore_text)
                    if ok:
                        st.session_state.backup_notice = ("success", message)
                        st.rerun()
                    else:
                        st.error(message)

            if not st.session_state.my_anime_list:
                st.write("아직 추가한 애니가 없습니다. 위 검색창에서 작품을 추가해보세요.")
            else:

                library_filter = ""
                if st.session_state.show_library_search:
                    library_filter = st.text_input(
                        "내 목록 검색",
                        key="library_filter",
                        placeholder="제목 검색",
                        label_visibility="collapsed"
                    ).strip().lower()

                library_cards = build_library_cards(library_filter)
                normal_cards = [item for item in library_cards if not item['needs_n_badge']]
                normal_cards.sort(key=lambda item: item['title'])
                total_count = sum(1 for info in st.session_state.my_anime_list.values() if not is_dropped(info))
                count_text = f"총 {total_count}개" if not library_filter else f"총 {total_count}개 · 검색 {len(normal_cards)}개"
                st.markdown(f"<div class='library-count'>{count_text}</div>", unsafe_allow_html=True)

                if not normal_cards:
                    if library_filter:
                        st.write("검색 결과가 없습니다.")
                    else:
                        st.write("새 화가 있는 작품은 새 화 탭에서 확인하세요.")
                else:
                    render_anime_card_grid(normal_cards, "list_card")

            render_library_schedule("list")

        elif active_main_tab == "보류":
            st.subheader("보류 목록")
            dropped_items = [(title, info) for title, info in st.session_state.my_anime_list.items() if is_dropped(info)]
            st.markdown(f"<div class='library-count'>총 {len(dropped_items)}개</div>", unsafe_allow_html=True)

            if not dropped_items:
                st.write("보류한 애니가 없습니다.")
            else:
                dropped_items.sort(key=lambda item: item[0])
                dropped_cards = [
                    {"title": title, "info": info, "needs_n_badge": False}
                    for title, info in dropped_items
                ]
                render_library_tile_grid(dropped_cards, "dropped")

        elif active_main_tab == "찜":
            wish_items = list(st.session_state.wish_list.values())
            wish_items.sort(key=lambda item: item.get("title", ""))
            render_wish_cards(wish_items)

        elif active_main_tab == "신작 애니":
            sorted_all_animes = ensure_new_animes_loaded()
            render_new_anime_cards(sorted_all_animes, "new_tab")

        elif active_main_tab == "애니 소식":
            news_data = ensure_news_loaded()
            open_news_idx = st.query_params.get("open_news")
            if open_news_idx is not None:
                try:
                    selected_news_idx = int(open_news_idx)
                except ValueError:
                    selected_news_idx = -1
                if 0 <= selected_news_idx < len(news_data):
                    st.session_state.selected_news = news_data[selected_news_idx]
                    st.session_state.news_return_view = "main"
                    st.session_state.view = "news_detail"
                    del st.query_params["open_news"]
                    st.rerun()
                else:
                    del st.query_params["open_news"]
            news_loaded_label = st.session_state.news_loaded_at.strftime("%Y.%m.%d %H:%M 기준")
            render_news_menu(news_data, news_loaded_label, render_news_image, open_news_detail)

# --- 화면 2: 애니메이션 상세 화면 ---
elif st.session_state.view == 'detail':
    anime_title = st.session_state.selected_anime
    anime_info = st.session_state.my_anime_list.get(anime_title)

    if st.query_params.get("delete_anime") == anime_title:
        delete_anime(anime_title)
        st.query_params.clear()
        st.session_state.selected_anime = None
        st.session_state.selected_season = None
        st.session_state.view = 'main'
        st.rerun()

    if st.session_state.selected_season is not None:
        back_col, home_col = st.columns([1, 1], gap="small")
        with back_col:
            st.markdown("<span class='episode-top-actions-anchor'></span>", unsafe_allow_html=True)
            if st.button("뒤로가기", key="back_from_detail", use_container_width=True):
                st.session_state.selected_season = None
                st.rerun()
        with home_col:
            if st.button("메인화면", key="home_from_episode", use_container_width=True):
                st.session_state.selected_anime = None
                st.session_state.selected_season = None
                st.session_state.view = 'main'
                st.rerun()
    else:
        if st.button("뒤로가기", key="back_from_detail"):
            st.session_state.view = 'main'
            st.rerun()

    if anime_info:
        if "related_movies" not in anime_info:
            anime_info["related_movies"] = get_related_anime_movies_api(
                anime_title,
                anime_info.get("original_title", "")
            )
            save_app_data()
        elif refresh_related_movie_runtime(anime_info):
            save_app_data()

        last_watched_season = None
        last_watched_episode = None
        
        for season in anime_info.get('seasons', []):
            for i, ep in enumerate(season.get('episodes', []), 1):
                db_key = make_watch_key(anime_title, season, i)
                if get_watch_value(anime_title, season, i):
                    last_watched_season = season['name']
                    last_watched_episode = i

        if st.session_state.selected_season is None:
            st.markdown(
                f"<h1 class='detail-title'>{html.escape(anime_title)}</h1>",
                unsafe_allow_html=True
            )
            
            status_text = anime_info.get('display_status', '정보 없음')
            if last_watched_season and last_watched_episode:
                watched_text = f"{last_watched_season} {last_watched_episode}화까지"
            else:
                watched_text = "기록 없음"

            meta_col, drop_col, delete_col = st.columns([6, 1, 1], gap="small", vertical_alignment="center")
            with meta_col:
                st.markdown("<span class='detail-actions-anchor'></span>", unsafe_allow_html=True)
                st.markdown(
                    f"""
                    <div class="detail-meta-text">
                        {html.escape(status_text)}<br>
                        최근 {html.escape(watched_text)}
                    </div>
                    """,
                    unsafe_allow_html=True
                )
            with drop_col:
                drop_label = "복귀" if is_dropped(anime_info) else "보류"
                if st.button(drop_label, key=f"drop_detail_{get_anime_uid(anime_title, anime_info)}"):
                    toggle_dropped(anime_title)
                    st.rerun()
            with delete_col:
                if st.button("삭제", key=f"delete_detail_{get_anime_uid(anime_title, anime_info)}"):
                    delete_anime(anime_title)
                    st.query_params.clear()
                    st.session_state.selected_anime = None
                    st.session_state.selected_season = None
                    st.session_state.view = 'main'
                    st.rerun()
                
            st.divider()
            
            seasons = anime_info.get('seasons', [])
            related_movies = anime_info.get("related_movies", [])

            cols_per_row = 1
            for start_idx in range(0, len(seasons), cols_per_row):
                cols = st.columns(cols_per_row)
                for offset, season in enumerate(seasons[start_idx:start_idx + cols_per_row]):
                    with cols[offset]:
                        with st.container(border=True):
                            season_img = get_display_season_image(season, anime_info)
                            if season_img:
                                st.image(season_img, use_container_width=True)
                            st.markdown(f"**{anime_title} {season['name']}**")
                            
                            if season.get('subtitle'):
                                st.caption(season['subtitle'])
                            else:
                                st.caption("\u200b") 
                            
                            count_col, view_col = st.columns([7, 3], gap="small")
                            with count_col:
                                st.markdown("<span class='season-actions-anchor'></span>", unsafe_allow_html=True)
                                ep_count = len(season.get('episodes', []))
                                st.markdown(f"<div style='line-height: 1.9em; color: gray; font-size: 0.82em;'>총 {ep_count}부작</div>", unsafe_allow_html=True)
                            with view_col:
                                season_idx = start_idx + offset
                                if st.button("보기", key=f"sel_{season_idx}"):
                                    st.session_state.selected_season = season_idx
                                    st.rerun()

            if related_movies:
                st.divider()
                st.subheader("극장판/영화")

                for start_idx in range(0, len(related_movies), cols_per_row):
                    cols = st.columns(cols_per_row)
                    for offset, movie in enumerate(related_movies[start_idx:start_idx + cols_per_row]):
                        with cols[offset]:
                            with st.container(border=True):
                                movie_img = movie.get("img", "")
                                if movie_img and not is_generic_image_url(movie_img):
                                    st.image(movie_img, use_container_width=True)
                                st.markdown(
                                    f"<div class='movie-title'>{html.escape(movie.get('title', '제목 없음'))}</div>",
                                    unsafe_allow_html=True
                                )
                                st.markdown(
                                    f"<div class='movie-meta'>극장판 · {html.escape(movie.get('release_date', '정보 없음'))} · {format_runtime(movie.get('runtime'))}</div>",
                                    unsafe_allow_html=True
                                )
                                movie_watch_key = make_movie_watch_key(anime_title, movie)
                                watched_movie = st.session_state.watched_db.get(movie_watch_key, False)
                                toggle_label = "완료" if watched_movie else "시청"
                                watch_state_class = "movie-watch-done" if watched_movie else "movie-watch-pending"
                                spacer_col, watch_col = st.columns([8, 2], gap="small")
                                with spacer_col:
                                    st.markdown(f"<span class='movie-actions-anchor {watch_state_class}'></span>", unsafe_allow_html=True)
                                with watch_col:
                                    if st.button(toggle_label, key=f"movie_watch_{movie_watch_key}"):
                                        toggle_movie_watch(anime_title, movie)
                                        st.rerun()

        else:
            season_idx = st.session_state.selected_season
            season = anime_info['seasons'][season_idx]
            s_num = season.get('s_num', season_idx + 1) 
            
            st.title(f"{anime_title} {season['name']}")
            st.caption(season['subtitle'])
            season_img = get_display_season_image(season, anime_info)
            if season_img:
                st.image(season_img, use_container_width=True)
            st.divider()
            
            current_date_str = datetime.now().strftime('%Y.%m.%d')
            
            latest_ep_idx = -1
            for j, e in enumerate(season.get('episodes', [])):
                if e['date'] <= current_date_str:
                    latest_ep_idx = j

            for i, ep in enumerate(season.get('episodes', []), 1):
                if i > 1:
                    st.markdown("<div class='episode-row-divider'></div>", unsafe_allow_html=True)
                
                db_key = make_watch_key(anime_title, season, i)
                widget_key = f"widget_{db_key}"
                is_watched = get_watch_value(anime_title, season, i)
                
                is_future_episode = ep['date'] > current_date_str
                
                ep_title = ep.get('title', '').strip()
                display_title = f"{i}화"
                if ep_title:
                    display_title += f" : {ep_title}"
                if (i - 1) == latest_ep_idx and not is_watched:
                    display_title += " <span style='color:#ef4444;font-weight:800;'>N</span>"

                episode_state_class = ""
                if not is_future_episode:
                    episode_state_class = "episode-watch-done" if is_watched else "episode-watch-pending"

                row_text_col, row_action_col = st.columns([8.6, 1.4], gap="small")
                with row_text_col:
                    st.markdown(
                        f"""
                        <div class="episode-main {episode_state_class}">
                            <div class="episode-title">{display_title}</div>
                            <div class="episode-date">{html.escape(ep['date'])}</div>
                        </div>
                        """,
                        unsafe_allow_html=True
                    )
                with row_action_col:
                    st.markdown("<div class='episode-actions' style='display:flex;justify-content:flex-end;align-items:center;'>", unsafe_allow_html=True)
                    if not is_future_episode:
                        watch_label = "완료" if is_watched else "시청"
                        if st.button(watch_label, key=f"ep_watch_{db_key}"):
                            set_episode_watch(anime_title, season_idx, i, not is_watched)
                            st.rerun()
                    st.markdown("</div>", unsafe_allow_html=True)

# --- 화면 4: 기사 상세 보기 화면 ---
elif st.session_state.view == 'news_detail':
    news = st.session_state.selected_news
    
    if st.button("목록으로 돌아가기", key="back_from_news_detail"):
        st.session_state.selected_news = None
        st.session_state.view = "main"
        st.session_state.news_return_view = "main"
        st.rerun()

    if news:
        st.title(news['title'])
        source_text = f" · {news.get('source')}" if news.get('source') else ""
        st.caption(f"발행일: {news['date']}{source_text}")
        st.divider()
        render_news_image(news)
        if news.get('link'):
            render_article_link(news['link'])
        st.markdown(f"<div style='line-height: 1.8; font-size: 1.1em;'>{news.get('full_content', news['content'])}</div>", unsafe_allow_html=True)
        st.divider()

st.markdown("<div class='bottom-safe-space'></div>", unsafe_allow_html=True)
















