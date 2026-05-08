import json
import html
import re
import xml.etree.ElementTree as ET
from email.utils import parsedate_to_datetime
from pathlib import Path
from urllib.parse import quote_plus

import streamlit as st
import streamlit.components.v1 as components
import requests
from datetime import datetime

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

APP_DIR = Path(__file__).resolve().parent
DATA_FILE = APP_DIR / "anime_check_data.json"


def load_app_data():
    if not DATA_FILE.exists():
        return {"my_anime_list": {}, "watched_db": {}}
    try:
        with DATA_FILE.open("r", encoding="utf-8") as f:
            data = json.load(f)
        return {
            "my_anime_list": data.get("my_anime_list", {}),
            "watched_db": data.get("watched_db", {}),
        }
    except (json.JSONDecodeError, OSError):
        return {"my_anime_list": {}, "watched_db": {}}


def save_app_data():
    data = {
        "my_anime_list": st.session_state.get("my_anime_list", {}),
        "watched_db": st.session_state.get("watched_db", {}),
        "updated_at": datetime.now().isoformat(timespec="seconds"),
    }
    tmp_file = DATA_FILE.with_suffix(".tmp")
    with tmp_file.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    tmp_file.replace(DATA_FILE)

st.markdown("""
    <style>
    .main { max-width: 500px; margin: 0 auto; }
    .stButton>button, .stLinkButton>a { 
        border-radius: 12px !important; height: 3em !important; padding: 0 15px !important; 
        background-color: #f0f2f6 !important; border: 1px solid #d1d5db !important; 
        font-weight: bold !important; color: #31333F !important;
        text-align: left; text-decoration: none; display: inline-flex; align-items: center;
        white-space: nowrap !important; 
    }
    button[data-testid="baseButton-secondary"], .stLinkButton>a { width: fit-content !important; justify-content: flex-start; }
    button[data-testid="baseButton-secondary"]:hover, button[data-testid="baseButton-secondary"]:active, button[data-testid="baseButton-secondary"]:focus {
        background-color: #f0f2f6 !important; border: 1px solid #d1d5db !important; color: #31333F !important;
    }
    button[data-testid="baseButton-primary"] { width: 100% !important; justify-content: center !important; }
    button[data-testid="baseButton-primary"]:hover, button[data-testid="baseButton-primary"]:active, button[data-testid="baseButton-primary"]:focus {
        background-color: #f0f2f6 !important; border: 1px solid #d1d5db !important; color: #31333F !important;
    }
    .stImage img { object-fit: cover; height: 180px; border-radius: 10px; }
    
    .anime-title { 
        display: -webkit-box; 
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical; 
        overflow: hidden; 
        text-overflow: ellipsis; 
        height: 2.8em; 
        line-height: 1.4em; 
        margin-top: 10px; 
        margin-bottom: 3px; 
        font-weight: bold; 
    }
    
    .anime-genre { 
        color: #666666; 
        font-size: 0.75em; 
        margin-bottom: 3px; 
        white-space: nowrap; 
        overflow: hidden; 
        text-overflow: ellipsis; 
    }
    
    .date-text { display: flex; align-items: center; justify-content: flex-start; height: 100%; color: gray; font-size: 0.85em; }
    .news-date { color: gray; font-size: 0.8em; text-align: right; margin-top: 10px; }
    .anime-date { color: gray; font-size: 0.75em; margin-bottom: 10px; }
    .search-hint { color: #888888; font-size: 0.8em; text-align: left; margin-top: -10px; margin-bottom: 15px; }
    </style>
    """, unsafe_allow_html=True)


# === 2. 외부 API 통신 함수 ===

def tmdb_get(endpoint, params=None):
    if not TMDB_API_KEY:
        return {}

    url = f"https://api.themoviedb.org/3/{endpoint.lstrip('/')}"
    request_params = {"api_key": TMDB_API_KEY, "language": "ko-KR"}
    if params:
        request_params.update(params)

    try:
        res = requests.get(url, params=request_params, timeout=10)
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


@st.cache_data(ttl=3600, show_spinner=False)
def search_anime_api(query):
    if not TMDB_API_KEY:
        if query:
            return [{"id": 99999, "name": f"{query} (API 연동 테스트)", "poster_path": "", "first_air_date": "2024-01-01", "genre_ids": [16]}]
        return []

    res = tmdb_get("search/tv", {"query": query})
    return [
        item for item in res.get('results', [])
        if 16 in item.get('genre_ids', []) and item.get('original_language') == 'ja'
    ]


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
            "namu_link": f"https://namu.wiki/Go?q={quote_plus(title)}",
            "seasons": [{
                "s_num": 1, "name": "1기", "subtitle": "API 자동 불러오기 테스트",
                "img": "https://images.unsplash.com/photo-1520116468816-95b69f847357?w=500&h=300&fit=crop",
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
            "namu_link": f"https://namu.wiki/Go?q={quote_plus(title)}",
            "seasons": []
        }

    genres = " / ".join([g.get('name', '') for g in res.get('genres', []) if g.get('name')])
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

        s_img = f"https://image.tmdb.org/t/p/w500{s.get('poster_path')}" if s.get('poster_path') else "https://images.unsplash.com/photo-1520116468816-95b69f847357?w=500&h=300&fit=crop"
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

        seasons_data.append({
            "s_num": s_num,
            "name": s_name,
            "subtitle": subtitle,
            "img": s_img,
            "episodes": episodes
        })

    return {
        "tmdb_id": tv_id,
        "title": title,
        "day": day_en,
        "display_status": display_status,
        "start_date": start_date,
        "genre": genres,
        "namu_link": f"https://namu.wiki/Go?q={quote_plus(title)}",
        "seasons": seasons_data
    }


@st.cache_data(ttl=3600, show_spinner=False)
def get_trending_anime_api(page=1):
    if not TMDB_API_KEY:
        return [
            {"id": 1, "name": "최근 핫한 애니 1", "poster_path": "", "first_air_date": "2024-05-01", "genre_ids": [16]}
        ]

    current_year = datetime.now().year
    recent_date = f"{current_year - 1}-01-01"
    today_date = datetime.now().strftime('%Y-%m-%d')
    res = tmdb_get("discover/tv", {
        "with_genres": 16,
        "with_original_language": "ja",
        "sort_by": "popularity.desc",
        "first_air_date.gte": recent_date,
        "first_air_date.lte": today_date,
        "page": page,
    })
    return res.get('results', [])

# === 3. 세션 상태 관리 및 콜백 함수 ===

if 'view' not in st.session_state: st.session_state.view = 'main'
if 'selected_anime' not in st.session_state: st.session_state.selected_anime = None
if 'selected_season' not in st.session_state: st.session_state.selected_season = None
if 'is_editing' not in st.session_state: st.session_state.is_editing = False
if 'selected_news' not in st.session_state: st.session_state.selected_news = None
if 'search_box' not in st.session_state: st.session_state.search_box = "" 
if 'news_return_view' not in st.session_state: st.session_state.news_return_view = 'main'

if 'data_loaded' not in st.session_state:
    saved_data = load_app_data()
    st.session_state.watched_db = saved_data.get("watched_db", {})
    st.session_state.my_anime_list = saved_data.get("my_anime_list", {})
    st.session_state.data_loaded = True

if 'watched_db' not in st.session_state:
    st.session_state.watched_db = {}
if 'my_anime_list' not in st.session_state:
    st.session_state.my_anime_list = {}

# --- 과거 데이터 마이그레이션 (자가 치유 로직) ---
current_date_str = datetime.now().strftime('%Y.%m.%d')
existing_data_changed = False
for title, info in st.session_state.my_anime_list.items():
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

if existing_data_changed:
    save_app_data()
# --------------------------------------------------------

def get_anime_uid(title, info=None):
    info = info or st.session_state.my_anime_list.get(title, {})
    return str(info.get("tmdb_id") or info.get("id") or title)


def make_watch_key(title, season, ep_idx):
    info = st.session_state.my_anime_list.get(title, {})
    anime_uid = get_anime_uid(title, info)
    season_num = season.get("s_num") or season.get("name", "season")
    return f"chk_{anime_uid}_s{season_num}_e{ep_idx}"


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


def add_anime_to_list(tv_id, title):
    st.session_state.my_anime_list[title] = get_anime_details_api(tv_id, title)
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


def on_checkbox_change(a_title, clicked_s_idx, clicked_ep_idx, w_key):
    is_checked = st.session_state[w_key]
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

def clear_search():
    st.session_state.search_box = ""

def add_direct_and_clear(tv_id, title):
    add_anime_to_list(tv_id, title)
    st.session_state.search_box = ""


NEWS_FALLBACK_IMAGE = "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=500&h=300&fit=crop"
NEWS_FEEDS = [
    {
        "name": "Google News",
        "url": f"https://news.google.com/rss/search?q={quote_plus('애니메이션 OR 애니 신작 성우 극장판')}&hl=ko&gl=KR&ceid=KR:ko",
    },
    {
        "name": "Anime News Network",
        "url": "https://www.animenewsnetwork.com/all/rss.xml?ann-edition=us",
    },
]


def strip_html(text):
    text = html.unescape(text or "")
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def parse_rss_date(date_text):
    if not date_text:
        return "", "0000-00-00T00:00:00"
    try:
        dt = parsedate_to_datetime(date_text)
        if dt.tzinfo:
            dt = dt.astimezone()
        return dt.strftime("%Y.%m.%d"), dt.isoformat()
    except (TypeError, ValueError):
        return "", "0000-00-00T00:00:00"


def extract_rss_image(item, description):
    media_namespaces = [
        "{http://search.yahoo.com/mrss/}content",
        "{http://search.yahoo.com/mrss/}thumbnail",
    ]
    for tag in media_namespaces:
        media = item.find(tag)
        if media is not None and media.attrib.get("url"):
            return media.attrib["url"]

    match = re.search(r'<img[^>]+src=["\']([^"\']+)', description or "", re.IGNORECASE)
    if match:
        return html.unescape(match.group(1))
    return NEWS_FALLBACK_IMAGE


def parse_rss_feed(xml_bytes, feed_name):
    root = ET.fromstring(xml_bytes)
    items = []
    for item in root.findall(".//item"):
        title = strip_html(item.findtext("title"))
        link = (item.findtext("link") or "").strip()
        description_raw = item.findtext("description") or ""
        summary = strip_html(description_raw)
        pub_date = item.findtext("pubDate") or item.findtext("published") or item.findtext("updated")
        date_label, sort_date = parse_rss_date(pub_date)
        source_node = item.find("source")
        source = source_node.text.strip() if source_node is not None and source_node.text else feed_name

        if not title:
            continue

        if " - " in title and feed_name == "Google News":
            title, source_from_title = title.rsplit(" - ", 1)
            source = source or source_from_title

        content = summary[:90] + "..." if len(summary) > 90 else summary
        full_content = summary or "요약을 불러오지 못했습니다. 원문 링크에서 자세한 내용을 확인하세요."
        if link:
            full_content += f"<br><br><a href='{link}' target='_blank'>원문 기사 보기</a>"

        items.append({
            "title": title,
            "content": content or source,
            "full_content": full_content,
            "date": date_label or "날짜 없음",
            "sort_date": sort_date,
            "img": extract_rss_image(item, description_raw),
            "source": source,
            "link": link,
        })
    return items


@st.cache_data(ttl=1800, show_spinner=False)
def get_anime_news(max_items=12):
    collected = []
    headers = {"User-Agent": "Mozilla/5.0 anime-checker/1.0"}

    for feed in NEWS_FEEDS:
        try:
            res = requests.get(feed["url"], headers=headers, timeout=10)
            res.raise_for_status()
            collected.extend(parse_rss_feed(res.content, feed["name"]))
        except (requests.RequestException, ET.ParseError):
            continue

    deduped = []
    seen_titles = set()
    for item in collected:
        key = re.sub(r"\W+", "", item["title"].lower())
        if key in seen_titles:
            continue
        seen_titles.add(key)
        deduped.append(item)

    deduped.sort(key=lambda item: item.get("sort_date", ""), reverse=True)
    if deduped:
        return deduped[:max_items]

    return [{
        "title": "애니 소식을 불러오지 못했습니다",
        "content": "네트워크 연결 또는 RSS 제공 상태를 확인해주세요.",
        "full_content": "뉴스 RSS를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.",
        "date": datetime.now().strftime("%Y.%m.%d"),
        "sort_date": datetime.now().isoformat(),
        "img": NEWS_FALLBACK_IMAGE,
        "source": "앱 안내",
        "link": "",
    }]


news_data = get_anime_news()

# --- 화면 1: 메인 화면 ---
if st.session_state.view == 'main':
    
    search_input = st.text_input("애니메이션 검색", key="search_box", placeholder="작품명 검색 (API 연동)", label_visibility="collapsed")
    st.markdown("<div class='search-hint'>[안내] 검색어를 입력하고 키보드의 완료나 엔터를 누르세요.</div>", unsafe_allow_html=True)
    
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
            result_cols = st.columns(3)
            for idx, item in enumerate(search_results):
                title = item['name']
                tv_id = item['id']
                rep_img = f"https://image.tmdb.org/t/p/w500{item['poster_path']}" if item.get('poster_path') else "https://images.unsplash.com/photo-1520116468816-95b69f847357?w=500&h=300&fit=crop"
                
                with result_cols[idx % 3]:
                    with st.container(border=True):
                        st.image(rep_img, use_container_width=True)
                        st.markdown(f"<div class='anime-title'>{title}</div>", unsafe_allow_html=True)
                        
                        if title in st.session_state.my_anime_list:
                            st.caption("목록에 있음")
                        else:
                            st.button("목록 추가", key=f"add_api_{tv_id}", on_click=add_direct_and_clear, args=(tv_id, title))
            
    else:
        st.divider()

        library_tab, new_anime_tab, news_tab = st.tabs(["내 보관함", "신작 애니", "애니 소식"])

        with library_tab:
            current_date_str = datetime.now().strftime('%Y.%m.%d')
            list_col, btn_edit = st.columns([7.5, 2.5])
            with list_col:
                st.subheader("내 시청 목록")
            with btn_edit:
                st.markdown("<div style='margin-top: 0.5em;'></div>", unsafe_allow_html=True)
                edit_text = "편집 완료" if st.session_state.is_editing else "목록 편집"
                if st.button(edit_text, key="edit_my_list"):
                    st.session_state.is_editing = not st.session_state.is_editing
                    st.rerun()

            if not st.session_state.my_anime_list:
                st.write("아직 추가한 애니가 없습니다. 위 검색창에서 작품을 추가해보세요.")
            else:
                for title, info in list(st.session_state.my_anime_list.items()):
                    needs_n_badge = False
                    latest_aired_ep = None

                    for season in info.get('seasons', []):
                        for i, ep in enumerate(season.get('episodes', []), 1):
                            if ep['date'] <= current_date_str:
                                latest_aired_ep = {
                                    'season': season,
                                    'season_name': season['name'],
                                    'ep_num': i
                                }

                    if latest_aired_ep:
                        if not get_watch_value(title, latest_aired_ep['season'], latest_aired_ep['ep_num']):
                            needs_n_badge = True

                    if st.session_state.is_editing:
                        display_name = f"{title} [삭제]"
                        if st.button(display_name, key=f"del_{title}"):
                            delete_anime(title)
                            st.rerun()
                    else:
                        display_name = f"{title} :red[**N**]" if needs_n_badge else title
                        if st.button(display_name, key=f"main_{title}"):
                            st.session_state.selected_anime = title
                            st.session_state.selected_season = None
                            st.session_state.view = 'detail'
                            st.rerun()

            st.write("")
            st.divider()

            st.subheader("내 보관함 편성표")
            days_en = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            days_kr = ["월요일", "화요일", "수요일", "목요일", "금요일", "토요일", "일요일"]

            schedule_tabs = st.tabs(days_kr)
            for i, day_en in enumerate(days_en):
                with schedule_tabs[i]:
                    day_animes = {k: v for k, v in st.session_state.my_anime_list.items() if v.get('day') == day_en}
                    if not day_animes:
                        st.write("해당 요일에 맵핑된 애니가 없습니다.")
                    else:
                        for t_name, t_info in day_animes.items():
                            if st.button(t_name, key=f"sched_{day_en}_{t_name}"):
                                st.session_state.selected_anime = t_name
                                st.session_state.selected_season = None
                                st.session_state.view = 'detail'
                                st.rerun()

        with new_anime_tab:
            st.subheader("신작 애니")
            st.write("최근 방영을 시작한 애니메이션을 최신순으로 확인하세요.")
            st.divider()

            sorted_all_animes = get_trending_anime_api(page=1) + get_trending_anime_api(page=2)
            sorted_all_animes.sort(key=lambda item: item.get('first_air_date') or "0000-00-00", reverse=True)

            if not sorted_all_animes:
                st.write("신작 애니 정보를 불러오지 못했습니다.")
            else:
                rows = (len(sorted_all_animes) + 2) // 3
                for r in range(rows):
                    cols = st.columns(3)
                    for c in range(3):
                        idx = r * 3 + c
                        if idx < len(sorted_all_animes):
                            item = sorted_all_animes[idx]
                            title = item['name']
                            tv_id = item['id']
                            rep_img = f"https://image.tmdb.org/t/p/w500{item['poster_path']}" if item.get('poster_path') else "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=500&h=300&fit=crop"

                            genre_names = [TMDB_GENRE_MAP.get(gid, "") for gid in item.get('genre_ids', [])]
                            genre_names = [g for g in genre_names if g]
                            genre_str = ", ".join(genre_names) if genre_names else "애니메이션"

                            with cols[c]:
                                with st.container(border=True):
                                    st.image(rep_img, use_container_width=True)
                                    st.markdown(f"<div class='anime-title'>{title}</div>", unsafe_allow_html=True)
                                    st.markdown(f"<div class='anime-genre'>장르: {genre_str}</div>", unsafe_allow_html=True)
                                    st.markdown(f"<div class='anime-date'>방영일: {item.get('first_air_date', '').replace('-','.')}</div>", unsafe_allow_html=True)

                                    btn_c1, btn_c2 = st.columns(2)
                                    with btn_c1:
                                        st.link_button("정보", f"https://namu.wiki/Go?q={title}")
                                    with btn_c2:
                                        if title in st.session_state.my_anime_list:
                                            st.button("추가 완료", key=f"add_new_tab_{tv_id}", disabled=True)
                                        else:
                                            if st.button("목록 추가", key=f"add_new_tab_{tv_id}"):
                                                add_anime_to_list(tv_id, title)
                                                st.rerun()

        with news_tab:
            st.subheader("최신 애니 소식")
            st.write("RSS에서 가져온 최신 애니 관련 기사를 확인하세요.")
            st.divider()

            rows = (len(news_data) + 2) // 3
            for r in range(rows):
                cols = st.columns(3)
                for c in range(3):
                    idx = r * 3 + c
                    if idx < len(news_data):
                        news = news_data[idx]
                        with cols[c]:
                            with st.container(border=True):
                                st.image(news['img'], use_container_width=True)
                                if st.button(news['title'], key=f"news_tab_{idx}"):
                                    st.session_state.selected_news = news
                                    st.session_state.news_return_view = 'main'
                                    st.session_state.view = 'news_detail'
                                    st.rerun()
                                st.caption(news['content'])
                                if news.get('source'):
                                    st.caption(f"출처: {news['source']}")
                                st.markdown(f"<div class='news-date'>{news['date']}</div>", unsafe_allow_html=True)

# --- 화면 2: 애니메이션 상세 화면 ---
elif st.session_state.view == 'detail':
    anime_title = st.session_state.selected_anime
    anime_info = st.session_state.my_anime_list.get(anime_title)
    
    if st.button("뒤로가기", key="back_from_detail"):
        if st.session_state.selected_season is not None:
            st.session_state.selected_season = None
        else:
            st.session_state.view = 'main'
        st.rerun()

    if anime_info:
        last_watched_season = None
        last_watched_episode = None
        
        for season in anime_info.get('seasons', []):
            for i, ep in enumerate(season.get('episodes', []), 1):
                db_key = make_watch_key(anime_title, season, i)
                if get_watch_value(anime_title, season, i):
                    last_watched_season = season['name']
                    last_watched_episode = i

        if st.session_state.selected_season is None:
            st.title(f"{anime_title}")
            
            title_col1, title_col2 = st.columns([6, 4])
            with title_col1:
                st.write(f"**방영 상태:** {anime_info.get('display_status', '정보 없음')}")
                if last_watched_season and last_watched_episode:
                    st.markdown(f"**최근 시청:** :blue[{last_watched_season} {last_watched_episode}화까지 완료]")
                else:
                    st.markdown("**최근 시청:** 아직 시청 기록이 없습니다.")
            with title_col2:
                action_c1, action_c2 = st.columns(2)
                with action_c1:
                    st.link_button("정보", anime_info.get('namu_link', '#'))
                with action_c2:
                    if st.button("삭제", key=f"del_detail_{anime_title}"):
                        delete_anime(anime_title)
                        st.session_state.selected_anime = None
                        st.session_state.view = 'main' 
                        st.rerun() 
                
            st.divider()
            
            seasons = anime_info.get('seasons', [])
            rows = (len(seasons) + 1) // 2
            for r in range(rows):
                cols = st.columns(2)
                for c in range(2):
                    idx = r * 2 + c
                    if idx < len(seasons):
                        season = seasons[idx]
                        with cols[c]:
                            with st.container(border=True):
                                st.image(season['img'], use_container_width=True)
                                st.markdown(f"**{anime_title} {season['name']}**")
                                
                                if season.get('subtitle'):
                                    st.caption(season['subtitle'])
                                else:
                                    st.caption("\u200b") 
                                
                                btn_c1, btn_c2 = st.columns([6, 4])
                                with btn_c1:
                                    if st.button("시즌 보기", key=f"sel_{idx}"):
                                        st.session_state.selected_season = idx
                                        st.rerun()
                                with btn_c2:
                                    ep_count = len(season.get('episodes', []))
                                    st.markdown(f"<div style='margin-top: 0.5em; text-align: right; color: gray; font-size: 0.9em;'>총 {ep_count}부작</div>", unsafe_allow_html=True)
                                    
        else:
            season_idx = st.session_state.selected_season
            season = anime_info['seasons'][season_idx]
            s_num = season.get('s_num', season_idx + 1) 
            
            st.title(f"{anime_title} {season['name']}")
            st.caption(season['subtitle'])
            st.image(season['img'], use_container_width=True)
            st.divider()
            
            st.write("에피소드 리스트")
            current_date_str = datetime.now().strftime('%Y.%m.%d')
            
            latest_ep_idx = -1
            for j, e in enumerate(season.get('episodes', [])):
                if e['date'] <= current_date_str:
                    latest_ep_idx = j

            for i, ep in enumerate(season.get('episodes', []), 1):
                c1, c2, c3 = st.columns([6, 3, 1])
                
                db_key = make_watch_key(anime_title, season, i)
                widget_key = f"widget_{db_key}"
                is_watched = get_watch_value(anime_title, season, i)
                
                is_future_episode = ep['date'] > current_date_str
                
                with c1:
                    ep_title = ep.get('title', '').strip()
                    display_title = f"**{s_num}기 {i}화**"
                    if ep_title:
                        display_title += f" : {ep_title}"
                    if (i - 1) == latest_ep_idx and not is_watched:
                        display_title += " :red[**N**]"
                    st.write(display_title)
                    
                with c2:
                    st.markdown(f"<div class='date-text'>{ep['date']}</div>", unsafe_allow_html=True)
                with c3:
                    st.checkbox("", value=is_watched, key=widget_key, on_change=on_checkbox_change, args=(anime_title, season_idx, i, widget_key), label_visibility="collapsed", disabled=is_future_episode)

# --- 화면 4: 신작 애니 모아보기 화면 ---
elif st.session_state.view == 'new_animes':
    components.html("<script>window.parent.scrollTo(0,0);</script>", height=0)
    
    if st.button("목록으로 돌아가기", key="back_from_new_animes"):
        st.session_state.view = 'main'
        st.rerun()

    st.title("신작 애니 모아보기")
    st.write("최근 방영을 시작한 애니메이션을 최신순으로 확인하세요.")
    st.divider()

    sorted_all_animes = get_trending_anime_api(page=1) + get_trending_anime_api(page=2)
    
    def get_safe_date(item):
        return item.get('first_air_date') or "0000-00-00"
    
    sorted_all_animes.sort(key=get_safe_date, reverse=True)
    
    rows = (len(sorted_all_animes) + 2) // 3
    for r in range(rows):
        cols = st.columns(3)
        for c in range(3):
            idx = r * 3 + c
            if idx < len(sorted_all_animes):
                item = sorted_all_animes[idx]
                title = item['name']
                tv_id = item['id']
                rep_img = f"https://image.tmdb.org/t/p/w500{item['poster_path']}" if item.get('poster_path') else "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=500&h=300&fit=crop"

                genre_names = [TMDB_GENRE_MAP.get(gid, "") for gid in item.get('genre_ids', [])]
                genre_names = [g for g in genre_names if g]
                genre_str = ", ".join(genre_names) if genre_names else "애니메이션"

                with cols[c]:
                    with st.container(border=True):
                        st.image(rep_img, use_container_width=True)
                        st.markdown(f"<div class='anime-title'>{title}</div>", unsafe_allow_html=True)
                        
                        st.markdown(f"<div class='anime-genre'>장르: {genre_str}</div>", unsafe_allow_html=True)
                        st.markdown(f"<div class='anime-date'>방영일: {item.get('first_air_date', '').replace('-','.')}</div>", unsafe_allow_html=True)
                        
                        btn_c1, btn_c2 = st.columns(2)
                        with btn_c1:
                            st.link_button("정보", f"https://namu.wiki/Go?q={title}")
                        with btn_c2:
                            if title in st.session_state.my_anime_list:
                                st.button("추가 완료", key=f"add_new_view_{tv_id}", disabled=True)
                            else:
                                if st.button("목록 추가", key=f"add_new_view_{tv_id}"):
                                    add_anime_to_list(tv_id, title)
                                    st.rerun()

# --- 화면 5: 애니 소식 목록 화면 ---
elif st.session_state.view == 'news':
    components.html("<script>window.parent.scrollTo(0,0);</script>", height=0)

    if st.button("목록으로 돌아가기", key="back_from_news"):
        st.session_state.view = 'main'
        st.rerun()

    st.title("최신 애니 소식")
    st.write("관심 있는 소식을 골라 자세히 확인하세요.")
    st.divider()

    rows = (len(news_data) + 2) // 3
    for r in range(rows):
        cols = st.columns(3)
        for c in range(3):
            idx = r * 3 + c
            if idx < len(news_data):
                news = news_data[idx]
                with cols[c]:
                    with st.container(border=True):
                        st.image(news['img'], use_container_width=True)
                        if st.button(news['title'], key=f"news_list_{idx}"):
                            st.session_state.selected_news = news
                            st.session_state.news_return_view = 'news'
                            st.session_state.view = 'news_detail'
                            st.rerun()
                        st.caption(news['content'])
                        if news.get('source'):
                            st.caption(f"출처: {news['source']}")
                        st.markdown(f"<div class='news-date'>{news['date']}</div>", unsafe_allow_html=True)

# --- 화면 6: 기사 상세 보기 화면 ---
elif st.session_state.view == 'news_detail':
    news = st.session_state.selected_news
    
    if st.button("목록으로 돌아가기", key="back_from_news_detail"):
        st.session_state.selected_news = None
        st.session_state.view = st.session_state.get('news_return_view', 'main')
        st.rerun()

    if news:
        st.title(news['title'])
        source_text = f" · {news.get('source')}" if news.get('source') else ""
        st.caption(f"발행일: {news['date']}{source_text}")
        st.divider()
        st.image(news['img'], use_container_width=True)
        st.write("")
        st.markdown(f"<div style='line-height: 1.8; font-size: 1.1em;'>{news.get('full_content', news['content'])}</div>", unsafe_allow_html=True)
        st.divider()
