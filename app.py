import json
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

        s_name = f"{s_num}기"
        tmdb_name = s.get('name', '')
        if tmdb_name and "시즌" not in tmdb_name and "Season" not in tmdb_name and f"{s_num}기" not in tmdb_name:
            subtitle = tmdb_name
        else:
            subtitle = s.get('overview', '')[:30]
            if len(s.get('overview', '')) > 30:
                subtitle += "..."

        s_img = f"https://image.tmdb.org/t/p/w500{s.get('poster_path')}" if s.get('poster_path') else "https://images.unsplash.com/photo-1520116468816-95b69f847357?w=500&h=300&fit=crop"
        ep_res = tmdb_get(f"tv/{tv_id}/season/{s_num}")

        episodes = []
        for ep in ep_res.get('episodes', []):
            ep_date = ep.get('air_date')
            ep_num = ep.get('episode_number')
            episodes.append({
                "ep_num": ep_num,
                "title": ep.get('name') or f"{ep_num}화",
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
        if 's_num' not in season:
            season['s_num'] = idx + 1
            if not season['name'].endswith('기'):
                old_name = season['name']
                season['name'] = f"{idx + 1}기"
                if old_name and "시즌" not in old_name and "Season" not in old_name:
                    season['subtitle'] = old_name
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


news_data = [
    {"title": "귀멸의 칼날 신규 시즌", "content": "무한성 편 극장판 3부작 제작 결정", "full_content": "전 세계적인 인기를 끌고 있는 애니메이션 '귀멸의 칼날'의 최종 국면인 '무한성 편'이 극장판 3부작으로 제작되는 것이 공식 확정되었습니다.", "date": "2026.05.04", "img": "https://images.unsplash.com/photo-1578632292335-df3abbb0d586?w=400&h=300&fit=crop"},
    {"title": "7월 신작 라인업", "content": "여름 시즌 총 40편의 신작 방영 예정입니다.", "full_content": "올해 7월 여름 시즌을 맞아 총 40편에 달하는 대규모 신작 애니메이션들이 쏟아집니다.", "date": "2026.05.03", "img": "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=400&h=300&fit=crop"},
    {"title": "애니 페스티벌", "content": "다음 달 킨텍스에서 최대 규모 축제 개최.", "full_content": "국내 최대 규모의 종합 서브컬처 행사 '애니 페스티벌 2026'이 다음 달 일산 킨텍스에서 성대하게 열립니다.", "date": "2026.05.02", "img": "https://images.unsplash.com/photo-1520116468816-95b69f847357?w=400&h=300&fit=crop"}
]

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
                db_key = make_watch_key(title, latest_aired_ep['season'], latest_aired_ep['ep_num'])
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

        st.write("")
        st.divider()

        new_col, new_btn_col = st.columns([7.5, 2.5])
        with new_col:
            st.subheader("신작 애니")
        with new_btn_col:
            st.markdown("<div style='margin-top: 0.5em;'></div>", unsafe_allow_html=True)
            if st.button("신작 더보기", key="more_new_animes"):
                st.session_state.view = 'new_animes'
                st.rerun()
        
        trending_for_main = get_trending_anime_api(page=1)
        trending_for_main.sort(key=lambda x: x.get('first_air_date') or "0000-00-00", reverse=True)
        top_new_animes = trending_for_main[:3]
        
        new_cols = st.columns(3)
        for idx, item in enumerate(top_new_animes):
            title = item['name']
            tv_id = item['id']
            rep_img = f"https://image.tmdb.org/t/p/w500{item['poster_path']}" if item.get('poster_path') else "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=500&h=300&fit=crop"

            genre_names = [TMDB_GENRE_MAP.get(gid, "") for gid in item.get('genre_ids', [])]
            genre_names = [g for g in genre_names if g] 
            genre_str = ", ".join(genre_names) if genre_names else "애니메이션"

            with new_cols[idx % 3]:
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
                            st.button("추가 완료", key=f"add_new_main_{tv_id}", disabled=True)
                        else:
                            if st.button("목록 추가", key=f"add_new_main_{tv_id}"):
                                add_anime_to_list(tv_id, title)
                                st.rerun()
                                    
        st.write("")
        st.divider()

        st.subheader("최신 애니 소식")
        main_news = news_data[:6]
        
        rows = 2
        for r in range(rows):
            cols = st.columns(3)
            for c in range(3):
                idx = r * 3 + c
                if idx < len(main_news):
                    news = main_news[idx]
                    with cols[c]:
                        with st.container(border=True):
                            st.image(news['img'], use_container_width=True)
                            if st.button(news['title'], key=f"news_main_{idx}"):
                                st.session_state.selected_news = news
                                st.session_state.view = 'news_detail'
                                st.rerun()
                            st.caption(news['content'])
                            st.markdown(f"<div class='news-date'>{news['date']}</div>", unsafe_allow_html=True)

        if st.button("더보기", key="more_news", type="primary", use_container_width=True):
            st.session_state.view = 'news'
            st.rerun()

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
                    display_title = f"**{s_num}기 {i}화** : {ep['title']}"
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
                            st.session_state.view = 'news_detail'
                            st.rerun()
                        st.caption(news['content'])
                        st.markdown(f"<div class='news-date'>{news['date']}</div>", unsafe_allow_html=True)

# --- 화면 6: 기사 상세 보기 화면 ---
elif st.session_state.view == 'news_detail':
    news = st.session_state.selected_news
    
    if st.button("목록으로 돌아가기", key="back_from_news_detail"):
        st.session_state.selected_news = None
        st.session_state.view = 'news' 
        st.rerun()

    if news:
        st.title(news['title'])
        st.caption(f"발행일: {news['date']}")
        st.divider()
        st.image(news['img'], use_container_width=True)
        st.write("")
        st.markdown(f"<div style='line-height: 1.8; font-size: 1.1em;'>{news.get('full_content', news['content'])}</div>", unsafe_allow_html=True)
        st.divider()