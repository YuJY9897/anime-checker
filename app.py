import json
import base64
import html
import re
import xml.etree.ElementTree as ET
from email.utils import parsedate_to_datetime
from pathlib import Path
from urllib.parse import parse_qs, quote_plus, unquote, urljoin, urlparse

import streamlit as st
import streamlit.components.v1 as components
import requests
from datetime import datetime, timedelta

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
    if not DATA_FILE.exists():
        return {"my_anime_list": {}, "watched_db": {}}
    try:
        with DATA_FILE.open("r", encoding="utf-8") as f:
            data = json.load(f)
        return {
            "my_anime_list": data.get("my_anime_list", {}),
            "watched_db": data.get("watched_db", {}),
            "wish_list": data.get("wish_list", {}),
            "updated_at": data.get("updated_at", ""),
        }
    except (json.JSONDecodeError, OSError):
        return {"my_anime_list": {}, "watched_db": {}}


def normalize_app_data(data):
    if not isinstance(data, dict):
        return None
    my_anime_list = data.get("my_anime_list", {})
    watched_db = data.get("watched_db", {})
    wish_list = data.get("wish_list", {})
    if not isinstance(my_anime_list, dict) or not isinstance(watched_db, dict) or not isinstance(wish_list, dict):
        return None
    return {
        "my_anime_list": my_anime_list,
        "watched_db": watched_db,
        "wish_list": wish_list,
        "updated_at": data.get("updated_at", ""),
    }


def parse_app_data_json(raw):
    if not raw:
        return None
    try:
        if isinstance(raw, bytes):
            raw = raw.decode("utf-8-sig")
        return normalize_app_data(json.loads(raw))
    except (UnicodeDecodeError, json.JSONDecodeError, TypeError):
        return None


def save_app_data():
    data = {
        "my_anime_list": st.session_state.get("my_anime_list", {}),
        "watched_db": st.session_state.get("watched_db", {}),
        "wish_list": st.session_state.get("wish_list", {}),
        "updated_at": datetime.now().isoformat(timespec="seconds"),
    }
    tmp_file = DATA_FILE.with_suffix(".tmp")
    with tmp_file.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    tmp_file.replace(DATA_FILE)
    st.session_state.pending_local_save = True
    st.session_state.local_save_version = st.session_state.get("local_save_version", 0) + 1

def build_backup_json():
    data = {
        "my_anime_list": st.session_state.get("my_anime_list", {}),
        "watched_db": st.session_state.get("watched_db", {}),
        "wish_list": st.session_state.get("wish_list", {}),
        "updated_at": datetime.now().isoformat(timespec="seconds"),
    }
    return json.dumps(data, ensure_ascii=False, indent=2)


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

st.markdown("""
    <style>
    #MainMenu, footer, header, [data-testid="stToolbar"], [data-testid="stDecoration"],
    [data-testid="stStatusWidget"], [data-testid="stDeployButton"], .stDeployButton {
        display: none !important;
        visibility: hidden !important;
        height: 0 !important;
    }
    .viewerBadge_container__1QSob, .viewerBadge_link__1S137,
    a[href*="streamlit.io/cloud"], a[href*="streamlit.io"] {
        display: none !important;
        visibility: hidden !important;
        pointer-events: none !important;
    }
    div.block-container { padding-top: 0.5rem !important; padding-bottom: 4.25rem !important; }
    div[data-testid="stVerticalBlock"] { gap: 0.45rem !important; }
    div[data-testid="stHorizontalBlock"] { gap: 0.4rem !important; }
    div[data-testid="stVerticalBlockBorderWrapper"] { padding: 0.45rem !important; }
    div[data-testid="stMarkdownContainer"] p { margin-bottom: 0.2rem !important; }
    div[data-testid="stCaptionContainer"] { margin-top: -0.1rem !important; }
    div[data-testid="stDivider"] { margin-top: 0.45rem !important; margin-bottom: 0.45rem !important; }
    div[data-testid="stTabs"] button[role="tab"] { padding-top: 0.35rem !important; padding-bottom: 0.35rem !important; }
    div[data-testid="stTabs"] [data-baseweb="tab-panel"] { padding-top: 0.55rem !important; }
    h1 { font-size: 1.65rem !important; line-height: 1.25 !important; }
    h2, h3 { margin-top: 0.35rem !important; margin-bottom: 0.35rem !important; }
    @media (max-width: 640px) {
        h1 { font-size: 1.35rem !important; line-height: 1.3 !important; }
    }
    .main { max-width: 500px; margin: 0 auto; }
    .stButton>button, .stLinkButton>a { 
        border-radius: 10px !important; min-height: 2.35em !important; height: auto !important; padding: 5px 9px !important; 
        background-color: #f0f2f6 !important; border: 1px solid #d1d5db !important; 
        font-weight: bold !important; color: #31333F !important; font-size: 0.9rem !important;
        text-align: left; text-decoration: none; display: inline-flex; align-items: center;
        white-space: normal !important; overflow-wrap: anywhere !important; word-break: keep-all !important; line-height: 1.25 !important;
    }
    .stButton>button p, .stLinkButton>a p {
        white-space: normal !important; overflow-wrap: anywhere !important; word-break: keep-all !important; font-size: 0.9rem !important;
    }
    button[data-testid="baseButton-secondary"], .stLinkButton>a { width: 100% !important; max-width: 100% !important; justify-content: flex-start; }
    .compact-actions-anchor, .search-actions-anchor, .wish-actions-anchor, .season-actions-anchor { display: none; }
    div[data-testid="stHorizontalBlock"]:has(.compact-actions-anchor),
    div[data-testid="stHorizontalBlock"]:has(.search-actions-anchor),
    div[data-testid="stHorizontalBlock"]:has(.wish-actions-anchor),
    div[data-testid="stHorizontalBlock"]:has(.season-actions-anchor) {
        display: flex !important; flex-direction: row !important; align-items: center !important;
        justify-content: flex-end !important; gap: 6px !important; flex-wrap: nowrap !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.compact-actions-anchor) > div:first-child,
    div[data-testid="stHorizontalBlock"]:has(.search-actions-anchor) > div:first-child,
    div[data-testid="stHorizontalBlock"]:has(.wish-actions-anchor) > div:first-child,
    div[data-testid="stHorizontalBlock"]:has(.season-actions-anchor) > div:first-child {
        flex: 1 1 auto !important; width: auto !important; min-width: 0 !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.compact-actions-anchor) > div:not(:first-child),
    div[data-testid="stHorizontalBlock"]:has(.search-actions-anchor) > div:not(:first-child),
    div[data-testid="stHorizontalBlock"]:has(.wish-actions-anchor) > div:not(:first-child),
    div[data-testid="stHorizontalBlock"]:has(.season-actions-anchor) > div:not(:first-child) {
        flex: 0 0 64px !important; width: 64px !important; min-width: 58px !important;
        display: flex !important; align-items: center !important; justify-content: flex-end !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.compact-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.search-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.wish-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.season-actions-anchor) [data-testid="stButton"] button {
        width: auto !important; max-width: 64px !important; min-width: 42px !important;
        height: 28px !important; min-height: 28px !important; padding: 0 8px !important;
        font-size: 0.78rem !important; justify-content: center !important; text-align: center !important;
        white-space: nowrap !important;
    }
    button[data-testid="baseButton-secondary"]:hover, button[data-testid="baseButton-secondary"]:active, button[data-testid="baseButton-secondary"]:focus {
        background-color: #f0f2f6 !important; border: 1px solid #d1d5db !important; color: #31333F !important;
    }
    button[data-testid="baseButton-primary"] { width: 100% !important; justify-content: center !important; }
    button[data-testid="baseButton-primary"]:hover, button[data-testid="baseButton-primary"]:active, button[data-testid="baseButton-primary"]:focus {
        background-color: #f0f2f6 !important; border: 1px solid #d1d5db !important; color: #31333F !important;
    }
    .stImage img { object-fit: cover; height: 132px; border-radius: 8px; }
    
.anime-title {
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
        text-overflow: ellipsis;
        min-height: 2.35em;
        line-height: 1.25em;
        margin-top: 5px;
        margin-bottom: 3px;
        font-size: 0.9rem;
        font-weight: bold;
        word-break: keep-all;
        overflow-wrap: anywhere;
    }
    
    .anime-genre { 
        color: #666666; 
        font-size: 0.75em; 
        margin-bottom: 4px; 
        line-height: 1.35;
        white-space: nowrap; 
        overflow: hidden; 
        text-overflow: ellipsis; 
    }
    
    .date-text { display: flex; align-items: center; justify-content: flex-start; height: 100%; color: gray; font-size: 0.85em; }
    .news-date { color: gray; font-size: 0.8em; text-align: right; margin-top: 3px; }
    .anime-date { color: gray; font-size: 0.75em; margin-bottom: 7px; line-height: 1.5; }
    .search-hint { color: #888888; font-size: 0.78em; text-align: left; margin-top: -12px; margin-bottom: 6px; }
    .library-count {
        color: #8a8f98; font-size: 0.76rem; text-align: right;
        margin-top: -0.2rem; margin-bottom: 0.2rem;
    }
    .detail-meta-actions {
        display: flex; align-items: center; justify-content: space-between; gap: 8px;
        margin: 2px 0 4px 0;
    }
    .detail-meta-text {
        min-width: 0; flex: 1; color: #4b5563; font-size: 0.86rem; line-height: 1.35;
    }
    .detail-action-row { display: inline-flex; align-items: center; gap: 6px; flex-shrink: 0; }
    .detail-action-btn {
        display: inline-flex; align-items: center; justify-content: center;
        min-width: 42px; height: 30px; padding: 0 9px; border-radius: 9px;
        background: #f0f2f6; border: 1px solid #d1d5db; color: #31333F !important;
        text-decoration: none !important; font-size: 0.8rem; font-weight: 700;
    }
    .inline-info-link {
        display: inline-flex; align-items: center; justify-content: center;
        width: auto !important; max-width: 58px !important; min-width: 42px !important;
        height: 28px !important; min-height: 28px !important; padding: 0 8px !important;
        border-radius: 9px; background: #f0f2f6; border: 1px solid #d1d5db;
        color: #31333F !important; text-decoration: none !important;
        font-size: 0.78rem !important; font-weight: 700; line-height: 1 !important;
        box-sizing: border-box;
    }
    .inline-info-link:visited, .inline-info-link:hover, .inline-info-link:active {
        color: #31333F !important; text-decoration: none !important;
    }
    .detail-action-btn.danger { color: #b91c1c !important; }
    .library-title-actions-anchor, .detail-actions-anchor { display: none; }
    div[data-testid="stHorizontalBlock"]:has(.library-title-actions-anchor),
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) {
        display: flex !important; flex-direction: row !important; align-items: center !important;
        justify-content: space-between !important; gap: 6px !important; flex-wrap: nowrap !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.library-title-actions-anchor) > div:first-child,
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) > div:first-child {
        flex: 1 1 auto !important; width: auto !important; min-width: 0 !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.library-title-actions-anchor) > div:nth-child(2) {
        flex: 0 0 58px !important; width: 58px !important; min-width: 58px !important;
        display: flex !important; justify-content: flex-end !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) > div:nth-child(2),
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) > div:nth-child(3),
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) > div:nth-child(4) {
        flex: 0 0 58px !important; width: 58px !important; min-width: 58px !important;
        display: flex !important; justify-content: flex-end !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.library-title-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) .stLinkButton > a,
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) .inline-info-link {
        width: auto !important; max-width: 58px !important; min-width: 42px !important;
        height: 28px !important; min-height: 28px !important; padding: 0 8px !important;
        font-size: 0.78rem !important; justify-content: center !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) > div:nth-child(3) [data-testid="stButton"] button {
        color: #92400e !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) > div:nth-child(4) [data-testid="stButton"] button {
        color: #b91c1c !important;
    }
    .movie-action-row {
        display: flex; align-items: center; justify-content: flex-end; gap: 6px; margin-top: 4px;
    }
    .movie-title {
        display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
        overflow: hidden; text-overflow: ellipsis; min-height: 2.5em;
        line-height: 1.25; font-size: 0.92rem; font-weight: 700; color: #31333F;
        margin: 3px 0 2px 0; word-break: keep-all; overflow-wrap: anywhere;
    }
    .movie-meta {
        color: #6b7280; font-size: 0.74rem; line-height: 1.25;
        margin-bottom: 4px; word-break: keep-all; overflow-wrap: anywhere;
    }
    .movie-action-btn {
        display: inline-flex; align-items: center; justify-content: center;
        min-width: 44px; height: 30px; padding: 0 9px; border-radius: 9px;
        background: #f0f2f6; border: 1px solid #d1d5db; color: #31333F !important;
        text-decoration: none !important; font-size: 0.8rem; font-weight: 700;
    }
    .movie-action-btn.done { color: #047857 !important; border-color: #6ee7b7; background: #ecfdf5; }
    .watch-done button {
        color: #047857 !important; border-color: #6ee7b7 !important; background: #ecfdf5 !important;
    }
    .watch-pending button {
        color: #374151 !important; border-color: #d1d5db !important; background: #f3f4f6 !important;
    }
    div[data-testid="stVerticalBlock"]:has(.watch-done) div[data-testid="stButton"] button {
        color: #047857 !important; border-color: #6ee7b7 !important; background: #ecfdf5 !important;
    }
    div[data-testid="stVerticalBlock"]:has(.watch-pending) div[data-testid="stButton"] button {
        color: #374151 !important; border-color: #d1d5db !important; background: #f3f4f6 !important;
    }
    .movie-actions-anchor { display: none; }
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) {
        display: flex !important; flex-direction: row !important; align-items: center !important;
        justify-content: flex-end !important; gap: 6px !important; flex-wrap: nowrap !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) > div:first-child {
        flex: 1 1 auto !important; width: auto !important; min-width: 0 !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) > div:nth-child(2),
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) > div:nth-child(3) {
        flex: 0 0 58px !important; width: 58px !important; min-width: 58px !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) > div:nth-child(2),
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) > div:nth-child(3) {
        display: flex !important; align-items: center !important; justify-content: flex-end !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) [data-testid="stButton"],
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) [data-testid="stLinkButton"],
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) .stLinkButton {
        margin: 0 !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) .stLinkButton > a,
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) .inline-info-link {
        width: auto !important; max-width: 58px !important; min-width: 42px !important;
        height: 28px !important; min-height: 28px !important; padding: 0 8px !important;
        font-size: 0.78rem !important; justify-content: center !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.movie-watch-done) > div:nth-child(2) [data-testid="stButton"] button {
        color: #047857 !important; border-color: #6ee7b7 !important; background: #ecfdf5 !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.movie-watch-pending) > div:nth-child(2) [data-testid="stButton"] button {
        color: #374151 !important; border-color: #d1d5db !important; background: #f3f4f6 !important;
    }
    .new-anime-actions-anchor { display: none; }
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) {
        display: flex !important; flex-direction: row !important; align-items: center !important;
        justify-content: flex-end !important; gap: 6px !important; flex-wrap: nowrap !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) > div:first-child {
        flex: 1 1 auto !important; width: auto !important; min-width: 0 !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) > div:nth-child(2),
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) > div:nth-child(3) {
        flex: 0 0 58px !important; width: 58px !important; min-width: 58px !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) .stLinkButton > a,
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) .inline-info-link {
        width: auto !important; max-width: 58px !important; min-width: 42px !important;
        height: 28px !important; min-height: 28px !important; padding: 0 8px !important;
        font-size: 0.78rem !important; justify-content: center !important;
    }
    .episode-watch-action {
        display: inline-flex; align-items: center; justify-content: center;
        min-width: 42px; height: 28px; padding: 0 8px; border-radius: 9px;
        background: #f0f2f6; border: 1px solid #d1d5db; color: #31333F !important;
        text-decoration: none !important; font-size: 0.78rem; font-weight: 700;
    }
    .episode-watch-action.done { color: #047857 !important; border-color: #6ee7b7; background: #ecfdf5; }
    .episode-row {
        display: flex; align-items: center; justify-content: space-between; gap: 10px;
        min-height: 42px;
    }
    .episode-main { min-width: 0; flex: 1; }
    .episode-title { font-size: 0.95rem; line-height: 1.3; font-weight: 700; color: #31333F; }
    .episode-date { margin-top: 2px; font-size: 0.78rem; line-height: 1.2; color: #6b7280; }
    .episode-actions { flex-shrink: 0; display: flex; align-items: center; justify-content: flex-end; }
    .episode-actions [data-testid="stButton"] button {
        width: auto !important; max-width: 48px !important; min-width: 42px !important;
        height: 28px !important; min-height: 28px !important;
        padding: 0 8px !important; font-size: 0.78rem !important;
        justify-content: center !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-main) {
        display: flex !important; flex-direction: row !important; align-items: center !important; gap: 8px !important;
        flex-wrap: nowrap !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-main) > div:first-child {
        flex: 1 1 auto !important; min-width: 0 !important; width: auto !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-main) > div:last-child {
        flex: 0 0 52px !important; width: 52px !important; min-width: 52px !important;
        display: flex !important; justify-content: flex-end !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-watch-done) > div:last-child [data-testid="stButton"] button {
        color: #047857 !important; border-color: #6ee7b7 !important; background: #ecfdf5 !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-watch-pending) > div:last-child [data-testid="stButton"] button {
        color: #374151 !important; border-color: #d1d5db !important; background: #f3f4f6 !important;
    }
    .episode-row-divider {
        height: 1px; background: #eef0f3; margin: 4px 0 5px 0;
    }
    div[data-testid="stCheckbox"] {
        width: 100% !important; display: flex !important; justify-content: flex-end !important;
    }
    div[data-testid="stCheckbox"] label,
    div[data-testid="stCheckbox"] [data-baseweb="checkbox"] {
        margin-left: auto !important; margin-right: 0 !important;
    }
    div[data-testid="stCheckbox"] [data-testid="stWidgetLabel"] { display: none !important; }
    html { scroll-behavior: smooth; }
    .scroll-top-btn {
        position: fixed; right: 18px; bottom: 18px; z-index: 999999;
        display: inline-flex; align-items: center; justify-content: center; gap: 6px;
        min-width: 52px; height: 44px; padding: 0 14px; border-radius: 999px;
        background: #31333F; color: white !important; text-decoration: none !important;
        font-size: 0.9rem; font-weight: 700; box-shadow: 0 6px 18px rgba(0,0,0,0.22);
        border: 1px solid rgba(255,255,255,0.25);
    }
    .scroll-top-btn:hover { background: #111827; color: white !important; }
    .bottom-safe-space { height: 5.5rem; }
    @media (max-width: 640px) {
        .scroll-top-btn { right: 12px; bottom: 12px; width: 44px; min-width: 44px; padding: 0; }
        .scroll-top-btn span { display: none; }
        .bottom-safe-space { height: 6.25rem; }
    }
    /* === App polish overrides === */
    html, body, [data-testid="stAppViewContainer"] { background: #f6f7f9 !important; }
    div.block-container {
        max-width: 560px !important;
        padding-left: 0.75rem !important;
        padding-right: 0.75rem !important;
        padding-top: 0.35rem !important;
        padding-bottom: 6.5rem !important;
    }
    h1 { font-size: 1.32rem !important; font-weight: 800 !important; letter-spacing: 0 !important; margin-bottom: 0.35rem !important; }
    h2, h3 { font-size: 1.03rem !important; font-weight: 800 !important; letter-spacing: 0 !important; }
    div[data-testid="stVerticalBlock"] { gap: 0.38rem !important; }
    div[data-testid="stHorizontalBlock"] { gap: 0.35rem !important; }
    div[data-testid="stVerticalBlockBorderWrapper"] {
        border: 1px solid #e6e8ee !important;
        border-radius: 12px !important;
        background: #ffffff !important;
        padding: 0.58rem !important;
        box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04) !important;
    }
    div[data-testid="stTabs"] { margin-top: 0.1rem !important; }
    div[data-testid="stTabs"] [role="tablist"] {
        gap: 0.25rem !important;
        border-bottom: 0 !important;
        overflow-x: auto !important;
        padding: 0.2rem 0 0.35rem 0 !important;
    }
    div[data-testid="stTabs"] button[role="tab"] {
        border-radius: 999px !important;
        background: #eceff3 !important;
        border: 1px solid transparent !important;
        color: #4b5563 !important;
        padding: 0.34rem 0.62rem !important;
        min-height: 30px !important;
        white-space: nowrap !important;
        font-size: 0.83rem !important;
        font-weight: 800 !important;
    }
    div[data-testid="stTabs"] button[aria-selected="true"] {
        background: #111827 !important;
        color: #ffffff !important;
        border-color: #111827 !important;
    }
    div[data-testid="stTextInput"] input, textarea {
        border-radius: 12px !important;
        border: 1px solid #d9dde5 !important;
        background: #ffffff !important;
        min-height: 38px !important;
        font-size: 0.92rem !important;
    }
    .stButton > button, .stDownloadButton > button, .stLinkButton > a {
        border-radius: 10px !important;
        min-height: 32px !important;
        padding: 5px 9px !important;
        font-size: 0.84rem !important;
        font-weight: 800 !important;
        line-height: 1.18 !important;
        border: 1px solid #d8dde6 !important;
        background: #f8fafc !important;
        color: #1f2937 !important;
        box-shadow: none !important;
    }
    .stButton > button:hover, .stDownloadButton > button:hover, .stLinkButton > a:hover {
        border-color: #b7c0cf !important;
        background: #eef2f7 !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.search-actions-anchor) > div:not(:first-child),
    div[data-testid="stHorizontalBlock"]:has(.wish-actions-anchor) > div:not(:first-child),
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) > div:not(:first-child),
    div[data-testid="stHorizontalBlock"]:has(.season-actions-anchor) > div:not(:first-child),
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) > div:not(:first-child),
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) > div:not(:first-child) {
        flex: 0 0 58px !important;
        width: 58px !important;
        min-width: 52px !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.search-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.wish-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.season-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) [data-testid="stButton"] button {
        width: auto !important;
        min-width: 42px !important;
        max-width: 58px !important;
        height: 28px !important;
        min-height: 28px !important;
        padding: 0 8px !important;
        font-size: 0.76rem !important;
        justify-content: center !important;
        text-align: center !important;
        white-space: nowrap !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-main) > div:last-child {
        flex: 0 0 56px !important;
        width: 56px !important;
        min-width: 56px !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-main) [data-testid="stButton"] button {
        width: auto !important;
        min-width: 44px !important;
        max-width: 54px !important;
        height: 29px !important;
        min-height: 29px !important;
        padding: 0 8px !important;
        font-size: 0.76rem !important;
        justify-content: center !important;
    }
    .anime-title, .movie-title, .episode-title {
        color: #111827 !important;
        word-break: keep-all !important;
        overflow-wrap: anywhere !important;
    }
    .anime-title { font-size: 0.86rem !important; min-height: 2.2em !important; line-height: 1.24 !important; }
    .anime-genre, .anime-date, .movie-meta, .episode-date { color: #6b7280 !important; }
    .episode-row-divider { background: #edf0f5 !important; margin: 6px 0 !important; }
    .news-date, .library-count { color: #7b8290 !important; font-size: 0.72rem !important; }
    .stImage img { height: 124px !important; border-radius: 10px !important; }
    @media (max-width: 430px) {
        div.block-container { padding-left: 0.55rem !important; padding-right: 0.55rem !important; }
        .stImage img { height: 112px !important; }
        .anime-title { font-size: 0.82rem !important; }
        div[data-testid="stTabs"] button[role="tab"] { font-size: 0.78rem !important; padding-left: 0.5rem !important; padding-right: 0.5rem !important; }
    }
    div[data-testid="stAlert"] {
        border-radius: 12px !important;
        border: 1px solid #fde68a !important;
        background: #fffbeb !important;
        color: #92400e !important;
    }
    div[data-testid="stAlert"] * { color: #92400e !important; }
    div[data-baseweb="segmented-control"], div[data-testid="stSegmentedControl"] {
        width: 100% !important;
    }
    div[data-baseweb="segmented-control"] button,
    div[data-testid="stSegmentedControl"] button {
        min-height: 32px !important;
        border-radius: 999px !important;
        font-size: 0.8rem !important;
        font-weight: 800 !important;
        white-space: nowrap !important;
    }
    div.block-container, div.block-container p, div.block-container h1, div.block-container h2, div.block-container h3,
    div[data-testid="stMarkdownContainer"], div[data-testid="stMarkdownContainer"] p {
        color: #111827 !important;
    }
    .search-hint { margin-top: 0.18rem !important; margin-bottom: 0.35rem !important; color: #6b7280 !important; }
    div[data-baseweb="segmented-control"] button,
    div[data-testid="stSegmentedControl"] button {
        background: #eef1f5 !important;
        border: 1px solid #d9dee8 !important;
        color: #374151 !important;
    }
    div[data-baseweb="segmented-control"] button p,
    div[data-testid="stSegmentedControl"] button p { color: #374151 !important; }
    div[data-baseweb="segmented-control"] button[aria-pressed="true"],
    div[data-testid="stSegmentedControl"] button[aria-pressed="true"],
    div[data-baseweb="segmented-control"] button[aria-selected="true"],
    div[data-testid="stSegmentedControl"] button[aria-selected="true"] {
        background: #111827 !important;
        border-color: #111827 !important;
        color: #ffffff !important;
    }
    div[data-baseweb="segmented-control"] button[aria-pressed="true"] p,
    div[data-testid="stSegmentedControl"] button[aria-pressed="true"] p,
    div[data-baseweb="segmented-control"] button[aria-selected="true"] p,
    div[data-testid="stSegmentedControl"] button[aria-selected="true"] p { color: #ffffff !important; }
    button[data-testid="baseButton-primary"] {
        background: #111827 !important;
        border-color: #111827 !important;
        color: #ffffff !important;
        justify-content: center !important;
        text-align: center !important;
    }
    button[data-testid="baseButton-primary"] p { color: #ffffff !important; }
    button[data-testid="baseButton-secondary"] p { color: #1f2937 !important; }
    div[data-testid="stHorizontalBlock"]:has(.main-nav-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.main-nav-anchor) + div[data-testid="stHorizontalBlock"] [data-testid="stButton"] button {
        min-height: 32px !important;
        justify-content: center !important;
        text-align: center !important;
        font-size: 0.8rem !important;
        padding-left: 4px !important;
        padding-right: 4px !important;
    }

    .app-nav {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 6px;
        margin: 0.35rem 0 0.55rem 0;
    }
    .app-nav-item {
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 34px;
        padding: 0 6px;
        border-radius: 11px;
        border: 1px solid #d8dde6;
        background: #ffffff;
        color: #1f2937 !important;
        text-decoration: none !important;
        font-size: 0.82rem;
        font-weight: 800;
        line-height: 1.1;
        word-break: keep-all;
        box-sizing: border-box;
    }
    .app-nav-item.active {
        background: #111827;
        border-color: #111827;
        color: #ffffff !important;
    }

    div[data-testid="stForm"] div[data-testid="stHorizontalBlock"] {
        display: flex !important;
        flex-direction: row !important;
        align-items: center !important;
        gap: 6px !important;
        flex-wrap: nowrap !important;
    }
    div[data-testid="stForm"] div[data-testid="stHorizontalBlock"] > div:first-child {
        flex: 1 1 auto !important;
        width: auto !important;
        min-width: 0 !important;
    }
    div[data-testid="stForm"] div[data-testid="stHorizontalBlock"] > div:last-child {
        flex: 0 0 64px !important;
        width: 64px !important;
        min-width: 64px !important;
    }
    div[data-testid="stForm"] [data-testid="stButton"] button {
        width: 64px !important;
        min-width: 64px !important;
        height: 38px !important;
        min-height: 38px !important;
        justify-content: center !important;
        padding: 0 !important;
    }
    </style>
    """, unsafe_allow_html=True)

st.markdown("<a class='scroll-top-btn' href='#top' title='맨 위로'>↑<span>맨 위</span></a>", unsafe_allow_html=True)

st.html(
    """
    <script>
    (function () {
        const appWindow = window.parent;
        const appDocument = appWindow.document;
        const handlerVersion = 7;
        const guardKey = "__animeCheckerBackGuardInstalledV7";
        const lastBackKey = "__animeCheckerLastBackAt";
        const suppressExitUntilKey = "__animeCheckerSuppressExitUntil";
        const delayMs = 1800;

        if (appWindow[guardKey]) {
            return;
        }
        appWindow[guardKey] = true;
        appWindow.__animeCheckerBackHandlerVersion = handlerVersion;
        appWindow[lastBackKey] = 0;
        appWindow[suppressExitUntilKey] = 0;

        function showBackToast(message) {
            let toast = appDocument.getElementById("anime-back-toast");
            if (!toast) {
                toast = appDocument.createElement("div");
                toast.id = "anime-back-toast";
                toast.style.position = "fixed";
                toast.style.left = "50%";
                toast.style.bottom = "78px";
                toast.style.transform = "translateX(-50%)";
                toast.style.zIndex = "2147483647";
                toast.style.padding = "11px 16px";
                toast.style.borderRadius = "999px";
                toast.style.background = "rgba(17, 24, 39, 0.94)";
                toast.style.color = "#ffffff";
                toast.style.fontSize = "14px";
                toast.style.fontWeight = "700";
                toast.style.boxShadow = "0 8px 24px rgba(0,0,0,0.24)";
                toast.style.whiteSpace = "nowrap";
                appDocument.body.appendChild(toast);
            }
            toast.textContent = message || "뒤로가기를 한 번 더 누르면 종료됩니다";
            toast.style.opacity = "1";
            appWindow.clearTimeout(appWindow.__animeBackToastTimer);
            appWindow.__animeBackToastTimer = appWindow.setTimeout(function () {
                toast.style.opacity = "0";
            }, 1500);
        }

        function getCurrentAppState() {
            const marker = appDocument.getElementById("anime-current-view");
            const markerState = marker ? {
                view: marker.getAttribute("data-view") || "unknown",
                selectedSeason: marker.getAttribute("data-selected-season") || "none",
                mainSection: marker.getAttribute("data-main-section") || "새 화"
            } : null;
            const liveState = appWindow.__animeCheckerCurrentView || markerState;
            return liveState || { view: "unknown", selectedSeason: "unknown", mainSection: "새 화" };
        }

        function findVisibleAppBackButton() {
            const labels = ["뒤로가기", "목록으로 돌아가기"];
            const buttons = Array.from(appDocument.querySelectorAll("button"));
            return buttons.find(function (button) {
                const text = (button.textContent || "").trim();
                const rect = button.getBoundingClientRect();
                return labels.some(function (label) { return text.includes(label); }) &&
                    rect.width > 0 && rect.height > 0 && !button.disabled;
            });
        }

        function clickVisibleAppBackButton() {
            const backButton = findVisibleAppBackButton();
            if (!backButton) {
                return false;
            }
            backButton.click();
            return true;
        }

        function updateUrlParam(name, value) {
            const url = new URL(appWindow.location.href);
            url.searchParams.set(name, value);
            appWindow.location.href = url.toString();
        }

        function requestAppBack(target) {
            updateUrlParam("app_back", target || "main");
        }

        function requestMainSection(label) {
            updateUrlParam("main_nav", label || "새 화");
        }

        function isMainLibraryTabSelected() {
            const state = getCurrentAppState();
            return state.view === "main" && (state.mainSection || "새 화") === "새 화";
        }

        function returnToMainTabIfNeeded() {
            const state = getCurrentAppState();
            if (state.view === "main" && (state.mainSection || "새 화") !== "새 화") {
                requestMainSection("새 화");
                appWindow.scrollTo({ top: 0, behavior: "smooth" });
                return true;
            }
            return false;
        }

        appWindow.history.pushState({ animeCheckerGuard: true }, "", appWindow.location.href);
        appWindow.addEventListener("popstate", function () {
            if (appWindow.__animeCheckerBackHandlerVersion !== handlerVersion) {
                return;
            }

            const state = getCurrentAppState();

            if (state.view === "detail") {
                appWindow[lastBackKey] = 0;
                appWindow[suppressExitUntilKey] = Date.now() + delayMs + 1200;
                if (clickVisibleAppBackButton()) {
                    appWindow.history.pushState({ animeCheckerGuard: true }, "", appWindow.location.href);
                    return;
                }
                requestAppBack(state.selectedSeason === "selected" ? "season_list" : "main");
                return;
            }

            if (state.view !== "main") {
                if (clickVisibleAppBackButton()) {
                    appWindow[lastBackKey] = 0;
                    appWindow[suppressExitUntilKey] = Date.now() + delayMs + 1200;
                    if (state.view === "detail" && state.selectedSeason !== "selected") {
                        appWindow.setTimeout(function () {
                            const latestState = getCurrentAppState();
                            if (latestState.view === "detail" && latestState.selectedSeason !== "selected") {
                                requestAppBack("main");
                            }
                        }, 650);
                    }
                    appWindow.history.pushState({ animeCheckerGuard: true }, "", appWindow.location.href);
                    return;
                }
                appWindow[lastBackKey] = 0;
                appWindow[suppressExitUntilKey] = Date.now() + delayMs + 1200;
                if (state.view === "detail" && state.selectedSeason !== "selected") {
                    requestAppBack("main");
                    return;
                }
                appWindow.setTimeout(function () {
                    clickVisibleAppBackButton();
                }, 120);
                appWindow.history.pushState({ animeCheckerGuard: true }, "", appWindow.location.href);
                return;
            }

            if (clickVisibleAppBackButton()) {
                appWindow[lastBackKey] = 0;
                appWindow[suppressExitUntilKey] = Date.now() + delayMs + 800;
                appWindow.history.pushState({ animeCheckerGuard: true }, "", appWindow.location.href);
                return;
            }

            if (returnToMainTabIfNeeded()) {
                appWindow[lastBackKey] = 0;
                appWindow[suppressExitUntilKey] = Date.now() + delayMs + 800;
                return;
            }

            const now = Date.now();
            if (!isMainLibraryTabSelected()) {
                appWindow[lastBackKey] = 0;
                appWindow.history.pushState({ animeCheckerGuard: true }, "", appWindow.location.href);
                return;
            }
            if (now < (appWindow[suppressExitUntilKey] || 0)) {
                appWindow[lastBackKey] = 0;
                appWindow.history.pushState({ animeCheckerGuard: true }, "", appWindow.location.href);
                return;
            }
            if (now - appWindow[lastBackKey] <= delayMs) {
                appWindow[guardKey] = false;
                appWindow.history.back();
                return;
            }
            appWindow[lastBackKey] = now;
            showBackToast("뒤로가기를 한 번 더 누르면 종료됩니다");
            appWindow.history.pushState({ animeCheckerGuard: true }, "", appWindow.location.href);
        });
    })();
    </script>
    """,
    unsafe_allow_javascript=True,
)


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
            "namu_link": make_info_url(title + " 극장판"),
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
                "namu_link": make_info_url(movie_title),
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
            "namu_link": make_info_url(title),
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
            "namu_link": make_info_url(title),
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
        "namu_link": make_info_url(title),
        "original_title": original_title,
        "poster_img": series_img,
        "related_movies": get_related_anime_movies_api(title, original_title),
        "seasons": seasons_data
    }
    return apply_season_split_rules(title, anime_info)


@st.cache_data(ttl=3600, show_spinner=False)
def get_trending_anime_api(page=1):
    if not TMDB_API_KEY:
        if page != 1:
            return []
        return [
            {"id": "demo_recent_1", "name": "최근 핫한 애니 1", "poster_path": "", "first_air_date": "2024-05-01", "genre_ids": [16]}
        ]

    current_year = datetime.now().year
    recent_date = f"{current_year - 1}-01-01"
    today_date = (datetime.now() + timedelta(days=120)).strftime('%Y-%m-%d')
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
if 'search_input_text' not in st.session_state: st.session_state.search_input_text = st.session_state.search_box
if 'library_filter' not in st.session_state: st.session_state.library_filter = ""
if 'show_library_search' not in st.session_state: st.session_state.show_library_search = False
if 'news_return_view' not in st.session_state: st.session_state.news_return_view = 'main'
if 'main_section' not in st.session_state: st.session_state.main_section = '새 화'
if 'pending_local_save' not in st.session_state: st.session_state.pending_local_save = False
if 'local_save_version' not in st.session_state: st.session_state.local_save_version = 0
if 'loaded_from_local_storage' not in st.session_state: st.session_state.loaded_from_local_storage = False

local_storage = LocalStorage() if LocalStorage is not None else None
local_storage_raw = None
if local_storage is not None:
    try:
        local_storage_raw = local_storage.getItem(BROWSER_STORAGE_KEY)
    except Exception:
        local_storage_raw = None

if 'data_loaded' not in st.session_state:
    if local_storage is not None:
        saved_data = {"my_anime_list": {}, "watched_db": {}, "wish_list": {}, "updated_at": ""}
    else:
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
    if app_back_target == "season_list" and st.session_state.view == "detail":
        st.session_state.selected_season = None
    else:
        st.session_state.selected_anime = None
        st.session_state.selected_season = None
        st.session_state.selected_news = None
        st.session_state.view = "main"
        st.session_state.main_section = "새 화"
    st.rerun()

main_nav_target = st.query_params.get("main_nav")
if main_nav_target:
    st.query_params.clear()
    st.session_state.main_section = main_nav_target
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

def render_info_link(url, label="정보"):
    safe_url = html.escape(normalize_info_url(url), quote=True)
    safe_label = html.escape(label, quote=True)
    st.markdown(
        f"<a class='inline-info-link' href='{safe_url}' target='_self' rel='noopener noreferrer'>{safe_label}</a>",
        unsafe_allow_html=True
    )

def make_info_url(query):
    return f"https://www.google.com/search?q={quote_plus((query or '').strip() + ' 나무위키')}"

def normalize_info_url(url):
    if not url or url == "#":
        return "#"

    parsed = urlparse(url)
    if "namu.wiki" in (parsed.netloc or ""):
        query = parse_qs(parsed.query).get("q", [""])[0]
        if not query and parsed.path.startswith("/w/"):
            query = unquote(parsed.path.removeprefix("/w/"))
        return make_info_url(query or "나무위키")

    return url


NEWS_FALLBACK_IMAGE = ""
NEWS_SEARCH_QUERY = (
    "(신작 애니 OR 애니메이션 신작 OR 애니 방영 예정 OR 애니메이션 공개일 OR "
    "애니메이션 새 시즌 OR 애니 2기 OR 애니 3기 OR 애니 후속작 OR "
    "애니 극장판 개봉 OR 애니 극장판 재개봉 OR 애니메이션 흥행 OR 애니메이션 인기) when:30d"
)
NEWS_TOPIC_KEYWORDS = [
    "방영", "방송", "공개", "공개일", "방영일", "방송일", "예정", "확정", "신작",
    "시즌", "새 시즌", "신시즌", "후속작", "속편", "2기", "3기", "4기", "5기",
    "제작 결정", "제작 확정", "제작 발표", "티저", "PV", "예고편",
    "극장판", "개봉", "재개봉", "상영", "특별상영",
    "흥행", "인기", "화제", "박스오피스", "관객", "누적 관객", "순위", "랭킹",
    "넷플릭스", "라프텔", "애니플러스", "애니맥스", "티빙", "왓챠", "OTT"
]
NEWS_ANIME_KEYWORDS = [
    "애니", "애니메이션", "극장판", "라프텔", "애니플러스", "애니맥스", "성우",
    "만화 원작", "일본 만화", "라이트노벨", "라노벨", "오리지널 애니"
]
NEWS_EXCLUDE_KEYWORDS = [
    "리뷰", "후기", "칼럼", "굿즈", "피규어", "게임", "할인", "이벤트",
    "웹툰", "드라마", "실사", "뮤지컬", "콘서트", "팝업", "콜라보 카페",
    "페스티벌", "영화제", "수상", "인터뷰", "감독",
    "review", "figure", "merch", "game"
]
NEWS_STRONG_TOPIC_KEYWORDS = [
    "방영 예정", "방영일", "방송일", "공개일", "공개 예정", "공개 확정",
    "신작", "새 시즌", "신시즌", "후속작", "속편", "2기", "3기", "4기", "5기",
    "제작 결정", "제작 확정", "제작 발표",
    "극장판", "개봉", "재개봉", "특별상영",
    "흥행", "박스오피스", "누적 관객", "관객 수", "관객수", "순위", "랭킹",
]
NEWS_WEAK_TOPIC_KEYWORDS = [
    "티저", "PV", "예고편", "인기", "화제", "OTT", "넷플릭스",
    "라프텔", "애니플러스", "애니맥스", "티빙", "왓챠",
]
NEWS_BLOCKED_IMAGE_DOMAINS = (
    "google.com", "google.co.kr", "gstatic.com", "googleusercontent.com", "ggpht.com",
    "googleapis.com", "googleusercontent.cn"
)
NEWS_BLOCKED_LINK_DOMAINS = (
    "news.google.com", "news.google.co.kr", "www.google.com", "google.com", "google.co.kr",
    "gstatic.com", "googleusercontent.com", "ggpht.com", "googleapis.com",
)
NEWS_KOREAN_DOMAINS = (
    "inven.co.kr", "gamefocus.co.kr", "thisisgame.com", "gamemeca.com", "gamechosun.co.kr",
    "ruliweb.com", "zdnet.co.kr", "newsis.com", "yna.co.kr", "hankyung.com",
    "naver.com", "daum.net", "mk.co.kr", "etnews.com", "sportsseoul.com",
    "cstimes.com", "cine21.com", "maxmovie.com", "kstar.kbs.co.kr", "sports.khan.co.kr",
)
NEWS_FEEDS = [
    {
        "name": "Google 뉴스 한국",
        "url": f"https://news.google.com/rss/search?q={quote_plus(NEWS_SEARCH_QUERY)}&hl=ko&gl=KR&ceid=KR:ko",
    },
    {
        "name": "Google 뉴스 한국 - 신작/새 시즌",
        "url": f"https://news.google.com/rss/search?q={quote_plus('(신작 애니 OR 애니메이션 신작 OR 애니 방영일 OR 애니 공개일 OR 애니메이션 새 시즌 OR 애니 후속작 OR 애니 2기 OR 애니 3기) when:45d')}&hl=ko&gl=KR&ceid=KR:ko",
    },
    {
        "name": "Google 뉴스 한국 - 라프텔",
        "url": f"https://news.google.com/rss/search?q={quote_plus('(라프텔 신작 애니 OR 라프텔 방영 예정 OR 애니플러스 신작) when:30d')}&hl=ko&gl=KR&ceid=KR:ko",
    },
    {
        "name": "Google 뉴스 한국 - 극장판/재개봉",
        "url": f"https://news.google.com/rss/search?q={quote_plus('(애니 극장판 개봉 OR 애니메이션 극장판 개봉 OR 애니 영화 개봉 OR 애니 극장판 재개봉 OR 애니메이션 재개봉) when:45d')}&hl=ko&gl=KR&ceid=KR:ko",
    },
    {
        "name": "Google 뉴스 한국 - 인기/흥행",
        "url": f"https://news.google.com/rss/search?q={quote_plus('(애니메이션 흥행 OR 애니메이션 인기 OR 애니 박스오피스 OR 애니 극장판 관객 OR 애니메이션 순위 OR 일본 애니 흥행) when:45d')}&hl=ko&gl=KR&ceid=KR:ko",
    },
]


def strip_html(text):
    text = html.unescape(text or "")
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def local_name(tag):
    return tag.rsplit("}", 1)[-1] if "}" in tag else tag


def find_first_child(node, names):
    wanted = set(names)
    for child in list(node):
        if local_name(child.tag) in wanted:
            return child
    return None


def find_first_text(node, names):
    child = find_first_child(node, names)
    return child.text if child is not None and child.text else ""


def find_first_link(node):
    for child in list(node):
        if local_name(child.tag) == "link":
            return child.attrib.get("href") or child.text or ""
    return find_first_text(node, ["id", "guid"])


def find_feed_items(root):
    return [node for node in root.iter() if local_name(node.tag) in {"item", "entry"}]


def count_keyword_hits(text, keywords):
    lowered = (text or "").lower()
    return sum(1 for keyword in keywords if keyword.lower() in lowered)


def get_news_relevance_score(item):
    text = f"{item.get('title', '')} {item.get('content', '')} {item.get('source', '')}"
    anime_hits = count_keyword_hits(text, NEWS_ANIME_KEYWORDS)
    strong_hits = count_keyword_hits(text, NEWS_STRONG_TOPIC_KEYWORDS)
    weak_hits = count_keyword_hits(text, NEWS_WEAK_TOPIC_KEYWORDS)
    title_text = item.get("title", "")

    score = anime_hits * 2 + strong_hits * 4 + weak_hits
    if count_keyword_hits(title_text, NEWS_STRONG_TOPIC_KEYWORDS):
        score += 3
    if "극장판" in title_text and any(k in title_text for k in ["개봉", "재개봉", "관객", "흥행", "박스오피스"]):
        score += 5
    if any(k in title_text for k in ["2기", "3기", "4기", "5기", "새 시즌", "후속작"]):
        score += 5
    return score


def is_schedule_news(item):
    text = f"{item.get('title', '')} {item.get('content', '')}".lower()
    if not is_korean_news(item):
        return False
    if any(keyword.lower() in text for keyword in NEWS_EXCLUDE_KEYWORDS):
        return False
    return get_news_relevance_score(item) >= 6


def is_korean_news(item):
    text = f"{item.get('title', '')} {item.get('content', '')} {item.get('full_content', '')}"
    hangul_count = len(re.findall(r"[가-힣]", text))
    letter_count = len(re.findall(r"[A-Za-z가-힣]", text))
    if hangul_count < 8:
        return False
    return not letter_count or (hangul_count / letter_count) >= 0.35


def get_domain(url):
    try:
        return urlparse(url).netloc.lower().removeprefix("www.")
    except ValueError:
        return ""


def is_blocked_domain(url, blocked_domains):
    domain = get_domain(url)
    return any(domain == blocked or domain.endswith(f".{blocked}") for blocked in blocked_domains)


def is_probable_article_link(url):
    if not url or is_blocked_domain(url, NEWS_BLOCKED_LINK_DOMAINS):
        return False
    lowered = url.lower()
    blocked_markers = ("favicon", "apple-touch-icon", "logo", "sprite", "manifest.json")
    blocked_exts = (".ico", ".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".css", ".js")
    path = urlparse(url).path.lower()
    return not any(marker in lowered for marker in blocked_markers) and not path.endswith(blocked_exts)


def is_korean_article_source(item, article_link):
    source = item.get("source", "")
    if len(re.findall(r"[가-힣]", source)) >= 2:
        return True
    domain = get_domain(article_link)
    return domain.endswith(".kr") or any(domain == allowed or domain.endswith(f".{allowed}") for allowed in NEWS_KOREAN_DOMAINS)


def normalize_candidate_url(candidate, base_url=""):
    candidate = html.unescape(unquote(candidate or "")).strip()
    if not candidate:
        return ""
    if candidate.startswith("//"):
        candidate = "https:" + candidate
    if base_url:
        candidate = urljoin(base_url, candidate)
    if not candidate.startswith(("http://", "https://")):
        return ""
    return candidate


def get_url_from_query(link):
    try:
        query = parse_qs(urlparse(link).query)
    except ValueError:
        return ""
    for key in ("url", "u", "q"):
        if query.get(key):
            candidate = normalize_candidate_url(query[key][0])
            if is_probable_article_link(candidate):
                return candidate
    return ""


def decode_google_news_url(link):
    try:
        parsed = urlparse(link)
    except ValueError:
        return ""
    if not parsed.netloc.endswith("news.google.com") or "/articles/" not in parsed.path:
        return ""

    encoded_text = parsed.path.rsplit("/", 1)[-1]
    if not encoded_text:
        return ""

    try:
        padded = encoded_text + ("=" * (-len(encoded_text) % 4))
        decoded = base64.urlsafe_b64decode(padded)
    except (ValueError, TypeError):
        return ""

    match = re.search(rb"https?://[^\x00-\x20\"'<>\\]+", decoded)
    if not match:
        return ""
    candidate = normalize_candidate_url(match.group(0).decode("utf-8", errors="ignore"))
    if is_probable_article_link(candidate):
        return candidate
    return ""


def extract_google_news_article_id(link):
    try:
        parsed = urlparse(link)
    except ValueError:
        return ""
    if not parsed.netloc.endswith("news.google.com") or "/articles/" not in parsed.path:
        return ""
    return parsed.path.rsplit("/", 1)[-1]


def decode_google_news_url_online(link, headers):
    article_id = extract_google_news_article_id(link)
    if not article_id:
        return ""

    try:
        res = requests.get(link, headers=headers, timeout=1.5)
        res.raise_for_status()
    except requests.RequestException:
        return ""

    timestamp_match = re.search(r'data-n-a-ts=["\']([^"\']+)["\']', res.text)
    signature_match = re.search(r'data-n-a-sg=["\']([^"\']+)["\']', res.text)
    if not timestamp_match or not signature_match:
        return extract_original_link_from_html(res.text, res.url)

    request_payload = [
        [[
            "Fbv4je",
            json.dumps([
                "garturlreq",
                [
                    ["ko-KR", "KR", ["FINANCE_TOP_INDICES", "WEB_TEST_1_0_0"], None, None, 1, 1, "KR:ko", None, 1, None, None, None, None, None, 0, 1],
                    "ko-KR",
                    "KR",
                    1,
                    [1, 1, 1],
                    1,
                    1,
                    None,
                    0,
                    0,
                    None,
                    0,
                ],
                article_id,
                int(timestamp_match.group(1)),
                signature_match.group(1),
            ], ensure_ascii=False, separators=(",", ":")),
            None,
            "generic",
        ]]
    ]

    try:
        decode_res = requests.post(
            "https://news.google.com/_/DotsSplashUi/data/batchexecute",
            headers={
                **headers,
                "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
                "Referer": "https://news.google.com/",
            },
            data={"f.req": json.dumps(request_payload, ensure_ascii=False, separators=(",", ":"))},
            timeout=1.5,
        )
        decode_res.raise_for_status()
        response_json = json.loads(decode_res.text.split("\n\n", 1)[1])
        for response_item in response_json:
            if not isinstance(response_item, list) or len(response_item) < 3 or not response_item[2]:
                continue
            payload = json.loads(response_item[2])
            if isinstance(payload, list) and len(payload) > 1:
                candidate = normalize_candidate_url(payload[1])
                if is_probable_article_link(candidate):
                    return candidate
    except (requests.RequestException, ValueError, IndexError, TypeError):
        return ""

    return ""


def extract_original_link_from_html(page_html, base_url):
    patterns = [
        r'data-n-au=["\']([^"\']+)',
        r'href=["\'](https?://[^"\']+)',
        r'(https?:\\/\\/[^"\']+)',
    ]
    for pattern in patterns:
        for raw in re.findall(pattern, page_html, re.IGNORECASE):
            candidate = raw.replace("\\/", "/")
            candidate = normalize_candidate_url(candidate, base_url)
            if is_probable_article_link(candidate):
                return candidate
    return ""


def resolve_original_article_link(link, description, headers):
    decoded_google_url = decode_google_news_url(link)
    if decoded_google_url:
        return decoded_google_url

    decoded_online_url = decode_google_news_url_online(link, headers)
    if decoded_online_url:
        return decoded_online_url

    query_url = get_url_from_query(link)
    if query_url:
        return query_url

    for raw_href in re.findall(r'href=["\']([^"\']+)', description or "", re.IGNORECASE):
        candidate = normalize_candidate_url(raw_href, link)
        if is_probable_article_link(candidate):
            return candidate

    if is_probable_article_link(link):
        return link

    try:
        res = requests.get(link, headers=headers, timeout=1.5, allow_redirects=True)
        res.raise_for_status()
        if is_probable_article_link(res.url):
            return res.url
        if "html" in res.headers.get("content-type", ""):
            original = extract_original_link_from_html(res.text, res.url)
            if original:
                return original
    except requests.RequestException:
        pass

    return link


def is_usable_news_image(url):
    if not url:
        return False
    if url.startswith("data:"):
        return False
    if is_blocked_domain(url, NEWS_BLOCKED_IMAGE_DOMAINS):
        return False
    lowered = url.lower()
    blocked_markers = ("logo", "favicon", "sprite", "placeholder", "default", "profile", "avatar")
    return not any(marker in lowered for marker in blocked_markers)


def is_loadable_news_image(url, headers):
    if not is_usable_news_image(url):
        return False
    try:
        image_headers = {
            **headers,
            "Accept": "image/webp,image/png,image/jpeg,image/*;q=0.8",
            "Referer": f"{urlparse(url).scheme}://{urlparse(url).netloc}/",
        }
        res = requests.get(url, headers=image_headers, timeout=1.5, stream=True, allow_redirects=True)
        res.raise_for_status()
        content_type = res.headers.get("content-type", "").lower()
        return content_type.startswith("image/") and "svg" not in content_type
    except requests.RequestException:
        return False


def fetch_news_image_bytes(url, headers):
    if not is_usable_news_image(url):
        return b""
    try:
        image_headers = {
            **headers,
            "Accept": "image/webp,image/png,image/jpeg,image/*;q=0.8",
            "Referer": f"{urlparse(url).scheme}://{urlparse(url).netloc}/",
        }
        res = requests.get(url, headers=image_headers, timeout=1.5, allow_redirects=True)
        res.raise_for_status()
        content_type = res.headers.get("content-type", "").lower()
        if not content_type.startswith("image/") or "svg" in content_type:
            return b""
        image_bytes = res.content
        if len(image_bytes) < 4096 or len(image_bytes) > 2_500_000:
            return b""
        return image_bytes
    except requests.RequestException:
        return b""


def normalize_image_url(raw_url, base_url):
    raw_url = html.unescape(raw_url or "").strip()
    if not raw_url:
        return ""
    if "," in raw_url and " " in raw_url:
        raw_url = raw_url.split(",", 1)[0].strip().split(" ", 1)[0].strip()
    return normalize_candidate_url(raw_url, base_url)


def first_usable_image_url(values, base_url):
    for value in values:
        if isinstance(value, dict):
            nested = first_usable_image_url(
                [
                    value.get("url"),
                    value.get("contentUrl"),
                    value.get("@id"),
                    value.get("thumbnailUrl"),
                ],
                base_url,
            )
            if nested:
                return nested
            continue
        if isinstance(value, list):
            nested = first_usable_image_url(value, base_url)
            if nested:
                return nested
            continue
        image_url = normalize_image_url(str(value or ""), base_url)
        if is_usable_news_image(image_url):
            return image_url
    return ""


def extract_json_ld_images(page_html, base_url):
    for match in re.finditer(
        r'<script[^>]+type=["\']application/ld\+json["\'][^>]*>([\s\S]*?)</script>',
        page_html,
        re.IGNORECASE,
    ):
        raw_json = html.unescape(match.group(1)).strip()
        if not raw_json:
            continue
        try:
            data = json.loads(raw_json)
        except json.JSONDecodeError:
            continue

        stack = data if isinstance(data, list) else [data]
        while stack:
            node = stack.pop(0)
            if isinstance(node, list):
                stack.extend(node)
                continue
            if not isinstance(node, dict):
                continue

            image_url = first_usable_image_url(
                [node.get("image"), node.get("thumbnailUrl"), node.get("primaryImageOfPage")],
                base_url,
            )
            if image_url:
                return image_url

            graph = node.get("@graph")
            if isinstance(graph, list):
                stack.extend(graph)
    return ""


def parse_rss_date(date_text):
    if not date_text:
        return "", "0000-00-00T00:00:00"
    try:
        dt = parsedate_to_datetime(date_text)
    except (TypeError, ValueError):
        try:
            dt = datetime.fromisoformat(date_text.replace("Z", "+00:00"))
        except (TypeError, ValueError):
            return "", "0000-00-00T00:00:00"
    if dt.tzinfo:
        dt = dt.astimezone()
    return dt.strftime("%Y.%m.%d"), dt.isoformat()


def extract_rss_image(item, description):
    for child in item.iter():
        child_name = local_name(child.tag)
        if child_name in {"content", "thumbnail"} and child.attrib.get("url"):
            image_url = normalize_candidate_url(child.attrib["url"])
            if is_usable_news_image(image_url):
                return image_url
        if child_name == "enclosure" and child.attrib.get("url"):
            enclosure_type = child.attrib.get("type", "")
            if not enclosure_type or enclosure_type.startswith("image"):
                image_url = normalize_candidate_url(child.attrib["url"])
                if is_usable_news_image(image_url):
                    return image_url

    for pattern in [
        r'<img[^>]+src=["\']([^"\']+)',
        r'<img[^>]+data-src=["\']([^"\']+)',
        r'<img[^>]+data-original=["\']([^"\']+)',
        r'<img[^>]+srcset=["\']([^"\']+)',
        r'<media:thumbnail[^>]+url=["\']([^"\']+)',
        r'<media:content[^>]+url=["\']([^"\']+)',
    ]:
        match = re.search(pattern, description or "", re.IGNORECASE)
        if match:
            image_url = normalize_image_url(match.group(1), "")
            if is_usable_news_image(image_url):
                return image_url
    return ""


def extract_article_image(page_html, base_url):
    meta_patterns = [
        r'<meta[^>]+property=["\']og:image["\'][^>]+content=["\']([^"\']+)',
        r'<meta[^>]+property=["\']og:image:url["\'][^>]+content=["\']([^"\']+)',
        r'<meta[^>]+property=["\']og:image:secure_url["\'][^>]+content=["\']([^"\']+)',
        r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']og:image["\']',
        r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']og:image:url["\']',
        r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']og:image:secure_url["\']',
        r'<meta[^>]+name=["\']twitter:image["\'][^>]+content=["\']([^"\']+)',
        r'<meta[^>]+name=["\']twitter:image:src["\'][^>]+content=["\']([^"\']+)',
        r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+name=["\']twitter:image["\']',
        r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+name=["\']twitter:image:src["\']',
        r'<meta[^>]+itemprop=["\']image["\'][^>]+content=["\']([^"\']+)',
        r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+itemprop=["\']image["\']',
        r'<link[^>]+rel=["\']image_src["\'][^>]+href=["\']([^"\']+)',
        r'<link[^>]+href=["\']([^"\']+)["\'][^>]+rel=["\']image_src["\']',
    ]
    for pattern in meta_patterns:
        match = re.search(pattern, page_html, re.IGNORECASE)
        if match:
            image_url = normalize_image_url(match.group(1), base_url)
            if is_usable_news_image(image_url):
                return image_url

    json_ld_image = extract_json_ld_images(page_html, base_url)
    if json_ld_image:
        return json_ld_image

    json_image_patterns = [
        r'"image"\s*:\s*"([^"]+)"',
        r'"thumbnailUrl"\s*:\s*"([^"]+)"',
        r'"contentUrl"\s*:\s*"([^"]+)"',
        r'"url"\s*:\s*"([^"]+\.(?:jpg|jpeg|png|webp)(?:\?[^"]*)?)"',
    ]
    for pattern in json_image_patterns:
        for match in re.finditer(pattern, page_html, re.IGNORECASE):
            image_url = normalize_image_url(match.group(1), base_url)
            if is_usable_news_image(image_url):
                return image_url

    image_attr_patterns = [
        r'<(?:article|main)[\s\S]*?<img[^>]+(?:data-src|data-original|srcset|src)=["\']([^"\']+)',
        r'<img[^>]+(?:data-src|data-original|srcset|src)=["\']([^"\']+)',
    ]
    for pattern in image_attr_patterns:
        for match in re.finditer(pattern, page_html, re.IGNORECASE):
            image_url = normalize_image_url(match.group(1), base_url)
            if is_usable_news_image(image_url):
                return image_url

    return ""


def get_article_image(link, headers):
    if not link:
        return ""
    try:
        article_headers = {
            **headers,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "ko-KR,ko;q=0.9,en-US;q=0.6,en;q=0.5",
        }
        res = requests.get(link, headers=article_headers, timeout=1.5, allow_redirects=True)
        res.raise_for_status()
        content_type = res.headers.get("content-type", "")
        if "html" not in content_type:
            return ""
        return extract_article_image(res.text, res.url)
    except requests.RequestException:
        return ""


def parse_rss_feed(xml_bytes, feed_name):
    root = ET.fromstring(xml_bytes)
    items = []
    for item in find_feed_items(root):
        title = strip_html(find_first_text(item, ["title"]))
        link = normalize_candidate_url(find_first_link(item))
        description_raw = find_first_text(item, ["description", "summary", "encoded", "content"]) or ""
        summary = strip_html(description_raw)
        pub_date = find_first_text(item, ["pubDate", "published", "updated", "date"])
        date_label, sort_date = parse_rss_date(pub_date)
        source = strip_html(find_first_text(item, ["source"])) or feed_name

        if not title or not link:
            continue

        content = summary[:90] + "..." if len(summary) > 90 else summary
        rss_image = extract_rss_image(item, description_raw)
        if not is_usable_news_image(rss_image):
            rss_image = ""

        items.append({
            "title": title,
            "content": content or source,
            "full_content": summary or "요약을 불러오지 못했습니다. 원문 링크에서 자세한 내용을 확인하세요.",
            "date": date_label or "날짜 없음",
            "sort_date": sort_date,
            "img": rss_image,
            "source": source,
            "link": link,
            "_summary": summary,
            "_description_raw": description_raw,
        })
    return items


@st.cache_data(ttl=86400, show_spinner=False)
def get_anime_news(max_items=12, image_extract_version=5):
    collected = []
    headers = {"User-Agent": "Mozilla/5.0 anime-checker/1.0"}
    started_at = datetime.now()

    def news_elapsed():
        return (datetime.now() - started_at).total_seconds()

    for feed in NEWS_FEEDS[:3]:
        if news_elapsed() > 5:
            break
        try:
            res = requests.get(feed["url"], headers=headers, timeout=1.5)
            res.raise_for_status()
            collected.extend(parse_rss_feed(res.content, feed["name"]))
        except (requests.RequestException, ET.ParseError):
            continue

    for item in collected:
        item["_relevance_score"] = get_news_relevance_score(item)

    schedule_items = [item for item in collected if is_schedule_news(item)]

    deduped = []
    seen_titles = set()
    for item in schedule_items:
        key = re.sub(r"\W+", "", item["title"].lower())
        if key in seen_titles:
            continue
        seen_titles.add(key)
        deduped.append(item)

    deduped.sort(key=lambda item: (item.get("_relevance_score", 0), item.get("sort_date", "")), reverse=True)
    candidates = deduped[:min(max_items, 6)]

    enriched = []
    for item in candidates:
        if news_elapsed() > 8:
            break
        description_raw = item.pop("_description_raw", "")
        article_link = resolve_original_article_link(item.get("link", ""), description_raw, headers)
        if not is_probable_article_link(article_link):
            continue
        if not is_korean_article_source(item, article_link):
            continue
        summary = item.pop("_summary", "")
        item["full_content"] = summary or "요약을 불러오지 못했습니다. 원문 링크에서 자세한 내용을 확인하세요."
        item["link"] = article_link
        image_url = item.get("img", "")
        image_bytes = fetch_news_image_bytes(image_url, headers)
        if not image_bytes:
            image_url = get_article_image(article_link, headers)
            image_bytes = fetch_news_image_bytes(image_url, headers)
        item["img"] = image_url if image_bytes else ""
        item["img_bytes"] = image_bytes
        enriched.append(item)
        if len(enriched) >= max_items:
            break
    if enriched:
        return enriched

    if deduped:
        fallback_items = []
        for item in deduped[:min(max_items, 6)]:
            item.pop("_description_raw", None)
            item.pop("_summary", None)
            item["img_bytes"] = b""
            if not is_probable_article_link(item.get("link", "")):
                item["link"] = ""
            fallback_items.append(item)
        return fallback_items

    return [{
        "title": "방영 예정 소식을 불러오지 못했습니다",
        "content": "현재 조건에 맞는 방영 예정/신작 소식을 찾지 못했습니다.",
        "full_content": "RSS에서 방영 예정, 공개일, 신작, 시즌 발표 중심의 소식을 찾지 못했습니다. 잠시 후 다시 시도해주세요.",
        "date": datetime.now().strftime("%Y.%m.%d"),
        "sort_date": datetime.now().isoformat(),
        "img": "",
        "source": "앱 안내",
        "link": "",
    }]


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


def render_main_nav(active_label):
    labels = ["새 화", "목록", "보류", "찜", "신작 애니", "애니 소식"]
    for row_start in range(0, len(labels), 3):
        cols = st.columns(3, gap="small")
        for offset, label in enumerate(labels[row_start:row_start + 3]):
            with cols[offset]:
                st.markdown("<span class='main-nav-anchor'></span>", unsafe_allow_html=True)
                if st.button(
                    label,
                    key=f"main_nav_btn_{row_start}_{offset}_{label}",
                    use_container_width=True,
                    type="primary" if label == active_label else "secondary",
                ):
                    st.session_state.main_section = label
                    st.session_state.selected_anime = None
                    st.session_state.selected_season = None
                    st.session_state.selected_news = None
                    st.session_state.view = "main"
                    st.rerun()


current_view_marker = html.escape(str(st.session_state.get("view", "main")), quote=True)
selected_season_marker = "none" if st.session_state.get("selected_season") is None else "selected"
main_section_marker = html.escape(str(st.session_state.get("main_section", "새 화")), quote=True)
st.markdown(
    f"<div id='anime-current-view' data-view='{current_view_marker}' "
    f"data-selected-season='{selected_season_marker}' data-main-section='{main_section_marker}' "
    f"style='display:none;'></div>",
    unsafe_allow_html=True,
)
st.html(
    f"""
    <script>
    window.parent.__animeCheckerCurrentView = {json.dumps({
        "view": st.session_state.get("view", "main"),
        "selectedSeason": selected_season_marker,
        "mainSection": st.session_state.get("main_section", "새 화"),
    }, ensure_ascii=False)};
    </script>
    """,
    unsafe_allow_javascript=True,
)

# --- 화면 1: 메인 화면 ---
if st.session_state.view == 'main':
    
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
            cols_per_row = 3
            for start_idx in range(0, len(cards), cols_per_row):
                cols = st.columns(cols_per_row, gap="small")
                for offset, card in enumerate(cards[start_idx:start_idx + cols_per_row]):
                    title = card['title']
                    info = card['info']
                    anime_uid = get_anime_uid(title, info)
                    with cols[offset]:
                        badge = " :red[**N**]" if card['needs_n_badge'] else ""
                        if st.button(f"{title}{badge}", key=f"{key_prefix}_{anime_uid}_{start_idx}_{offset}"):
                            st.session_state.selected_anime = title
                            st.session_state.selected_season = None
                            st.session_state.view = 'detail'
                            st.rerun()

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
                        for t_name, t_info in day_animes.items():
                            anime_uid = get_anime_uid(t_name, t_info)
                            if st.button(t_name, key=f"{key_prefix}_sched_{day_en}_{anime_uid}"):
                                st.session_state.selected_anime = t_name
                                st.session_state.selected_season = None
                                st.session_state.view = 'detail'
                                st.rerun()

        active_main_tab = st.session_state.get("main_section", "새 화")
        render_main_nav(active_main_tab)

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
                backup_col, restore_col = st.columns([1, 1], gap="small")
                with backup_col:
                    st.text_area(
                        "백업 내용",
                        value=build_backup_json(),
                        height=120,
                        key="backup_json_text",
                        help="파일 저장이 안 되는 폰에서는 이 내용을 복사해두세요."
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
                        "백업 불러오기",
                        type=["json"],
                        label_visibility="collapsed",
                        key="restore_backup_file"
                    )
                if backup_file is not None:
                    st.caption("불러오면 현재 목록과 시청 기록이 백업 파일 내용으로 바뀝니다.")
                    if st.button("불러오기", key="restore_backup_btn", use_container_width=True):
                        ok, message = restore_backup_file(backup_file)
                        if ok:
                            st.success(message)
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
                        st.success(message)
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
                    st.write("검색 결과가 없습니다.")
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
                cols_per_row = 3
                for start_idx in range(0, len(dropped_items), cols_per_row):
                    cols = st.columns(cols_per_row, gap="small")
                    for offset, (title, info) in enumerate(dropped_items[start_idx:start_idx + cols_per_row]):
                        anime_uid = get_anime_uid(title, info)
                        with cols[offset]:
                            if st.button(title, key=f"dropped_card_{anime_uid}_{start_idx}_{offset}"):
                                st.session_state.selected_anime = title
                                st.session_state.selected_season = None
                                st.session_state.view = 'detail'
                                st.rerun()

        elif active_main_tab == "찜":
            st.subheader("찜 목록")
            wish_items = list(st.session_state.wish_list.values())
            wish_items.sort(key=lambda item: item.get("title", ""))
            st.markdown(f"<div class='library-count'>총 {len(wish_items)}개</div>", unsafe_allow_html=True)

            if not wish_items:
                st.write("찜한 애니가 없습니다.")
            else:
                cols_per_row = 2
                for start_idx in range(0, len(wish_items), cols_per_row):
                    cols = st.columns(cols_per_row, gap="small")
                    for offset, item in enumerate(wish_items[start_idx:start_idx + cols_per_row]):
                        tv_id = item.get("id")
                        title = item.get("title", "제목 없음")
                        rep_img = item.get("img") or (f"https://image.tmdb.org/t/p/w500{item.get('poster_path')}" if item.get("poster_path") else "")
                        with cols[offset]:
                            with st.container(border=True):
                                if rep_img:
                                    st.image(rep_img, use_container_width=True)
                                st.markdown(f"<div class='anime-title'>{html.escape(title)}</div>", unsafe_allow_html=True)
                                spacer_col, add_col, remove_col = st.columns([5, 3, 2], gap="small")
                                with spacer_col:
                                    st.markdown("<span class='wish-actions-anchor'></span>", unsafe_allow_html=True)
                                with add_col:
                                    if title in st.session_state.my_anime_list:
                                        st.button("완료", key=f"wish_added_{tv_id}", disabled=True)
                                    elif st.button("추가", key=f"wish_add_{tv_id}"):
                                        add_anime_to_list(tv_id, title)
                                        st.rerun()
                                with remove_col:
                                    if st.button("삭제", key=f"wish_remove_{tv_id}"):
                                        st.session_state.wish_list.pop(str(tv_id), None)
                                        save_app_data()
                                        st.rerun()

        elif active_main_tab == "신작 애니":
            st.subheader("신작 애니")
            st.write("최근 방영을 시작한 애니메이션을 최신순으로 확인하세요.")
            st.divider()

            raw_new_animes = get_trending_anime_api(page=1) + get_trending_anime_api(page=2)
            seen_new_ids = set()
            sorted_all_animes = []
            for item in raw_new_animes:
                tv_id = item.get('id') or f"idx_{len(sorted_all_animes)}"
                if tv_id in seen_new_ids:
                    continue
                seen_new_ids.add(tv_id)
                sorted_all_animes.append(item)
            sorted_all_animes.sort(key=lambda item: item.get('first_air_date') or "0000-00-00", reverse=True)

            if not sorted_all_animes:
                st.write("신작 애니 정보를 불러오지 못했습니다.")
            else:
                cols_per_row = 1
                rows = (len(sorted_all_animes) + cols_per_row - 1) // cols_per_row
                for r in range(rows):
                    cols = st.columns(cols_per_row)
                    for c in range(cols_per_row):
                        idx = r * cols_per_row + c
                        if idx < len(sorted_all_animes):
                            item = sorted_all_animes[idx]
                            title = item['name']
                            tv_id = item['id']
                            rep_img = f"https://image.tmdb.org/t/p/w500{item['poster_path']}" if item.get('poster_path') else ""

                            genre_names = [TMDB_GENRE_MAP.get(gid, "") for gid in item.get('genre_ids', [])]
                            genre_names = [g for g in genre_names if g]
                            genre_str = ", ".join(genre_names) if genre_names else "애니메이션"

                            with cols[c]:
                                with st.container(border=True):
                                    if rep_img:
                                        st.image(rep_img, use_container_width=True)
                                    st.markdown(f"<div class='anime-title'>{html.escape(title)}</div>", unsafe_allow_html=True)
                                    st.markdown(f"<div class='anime-genre'>장르: {genre_str}</div>", unsafe_allow_html=True)
                                    st.markdown(f"<div class='anime-date'>방영일: {item.get('first_air_date', '').replace('-','.')}</div>", unsafe_allow_html=True)

                                    spacer_col, wish_col, add_col = st.columns([6, 2, 2], gap="small")
                                    with spacer_col:
                                        st.markdown("<span class='new-anime-actions-anchor'></span>", unsafe_allow_html=True)
                                    with wish_col:
                                        wish_label = "찜해제" if is_wished(tv_id) else "찜"
                                        if st.button(wish_label, key=f"wish_new_tab_{tv_id}_{idx}"):
                                            toggle_wish(tv_id, title, item)
                                            st.rerun()
                                    with add_col:
                                        if title in st.session_state.my_anime_list:
                                            st.button("완료", key=f"add_new_tab_{tv_id}_{idx}", disabled=True)
                                        else:
                                            if st.button("추가", key=f"add_new_tab_{tv_id}_{idx}"):
                                                add_anime_to_list(tv_id, title)
                                                st.rerun()

        elif active_main_tab == "애니 소식":
            news_data = ensure_news_loaded()
            news_loaded_label = st.session_state.news_loaded_at.strftime("%Y.%m.%d %H:%M 기준")
            news_title_col, news_time_col = st.columns([5, 4], gap="small", vertical_alignment="center")
            with news_title_col:
                st.subheader("최신 애니 소식")
            with news_time_col:
                st.markdown(f"<div class='library-count'>{news_loaded_label}</div>", unsafe_allow_html=True)
            st.write("방영 예정, 신작 공개일, 시즌 발표 중심의 소식을 확인하세요.")
            st.divider()

            for idx, news in enumerate(news_data):
                with st.container(border=True):
                    render_news_image(news)
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
            st.title(f"{anime_title}")
            
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

# --- 화면 4: 신작 애니 모아보기 화면 ---
elif st.session_state.view == 'new_animes':
    st.html("<script>window.parent.scrollTo(0,0);</script>", unsafe_allow_javascript=True)
    
    if st.button("목록으로 돌아가기", key="back_from_new_animes"):
        st.session_state.view = 'main'
        st.rerun()

    st.title("신작 애니 모아보기")
    st.write("최근 방영을 시작한 애니메이션을 최신순으로 확인하세요.")
    st.divider()

    raw_new_animes = get_trending_anime_api(page=1) + get_trending_anime_api(page=2)
    seen_new_ids = set()
    sorted_all_animes = []
    for item in raw_new_animes:
        tv_id = item.get('id') or f"idx_{len(sorted_all_animes)}"
        if tv_id in seen_new_ids:
            continue
        seen_new_ids.add(tv_id)
        sorted_all_animes.append(item)
    
    def get_safe_date(item):
        return item.get('first_air_date') or "0000-00-00"
    
    sorted_all_animes.sort(key=get_safe_date, reverse=True)
    
    cols_per_row = 1
    rows = (len(sorted_all_animes) + cols_per_row - 1) // cols_per_row
    for r in range(rows):
        cols = st.columns(cols_per_row)
        for c in range(cols_per_row):
            idx = r * cols_per_row + c
            if idx < len(sorted_all_animes):
                item = sorted_all_animes[idx]
                title = item['name']
                tv_id = item['id']
                rep_img = f"https://image.tmdb.org/t/p/w500{item['poster_path']}" if item.get('poster_path') else ""

                genre_names = [TMDB_GENRE_MAP.get(gid, "") for gid in item.get('genre_ids', [])]
                genre_names = [g for g in genre_names if g]
                genre_str = ", ".join(genre_names) if genre_names else "애니메이션"

                with cols[c]:
                    with st.container(border=True):
                        if rep_img:
                            st.image(rep_img, use_container_width=True)
                        st.markdown(f"<div class='anime-title'>{html.escape(title)}</div>", unsafe_allow_html=True)
                        
                        st.markdown(f"<div class='anime-genre'>장르: {genre_str}</div>", unsafe_allow_html=True)
                        st.markdown(f"<div class='anime-date'>방영일: {item.get('first_air_date', '').replace('-','.')}</div>", unsafe_allow_html=True)
                        
                        spacer_col, wish_col, add_col = st.columns([6, 2, 2], gap="small")
                        with spacer_col:
                            st.markdown("<span class='new-anime-actions-anchor'></span>", unsafe_allow_html=True)
                        with wish_col:
                            wish_label = "찜해제" if is_wished(tv_id) else "찜"
                            if st.button(wish_label, key=f"wish_new_view_{tv_id}_{idx}"):
                                toggle_wish(tv_id, title, item)
                                st.rerun()
                        with add_col:
                            if title in st.session_state.my_anime_list:
                                st.button("완료", key=f"add_new_view_{tv_id}_{idx}", disabled=True)
                            else:
                                if st.button("추가", key=f"add_new_view_{tv_id}_{idx}"):
                                    add_anime_to_list(tv_id, title)
                                    st.rerun()

# --- 화면 5: 애니 소식 목록 화면 ---
elif st.session_state.view == 'news':
    news_data = ensure_news_loaded()
    news_loaded_label = st.session_state.news_loaded_at.strftime("%Y.%m.%d %H:%M 기준")
    st.html("<script>window.parent.scrollTo(0,0);</script>", unsafe_allow_javascript=True)

    if st.button("목록으로 돌아가기", key="back_from_news"):
        st.session_state.view = 'main'
        st.rerun()

    news_title_col, news_time_col = st.columns([5, 4], gap="small", vertical_alignment="center")
    with news_title_col:
        st.title("최신 애니 소식")
    with news_time_col:
        st.markdown(f"<div class='library-count'>{news_loaded_label}</div>", unsafe_allow_html=True)
    st.write("관심 있는 소식을 골라 자세히 확인하세요.")
    st.divider()

    for idx, news in enumerate(news_data):
        with st.container(border=True):
            render_news_image(news)
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
        render_news_image(news)
        if news.get('link'):
            st.link_button("원문 기사 보기", news['link'], use_container_width=True)
        st.write("")
        st.markdown(f"<div style='line-height: 1.8; font-size: 1.1em;'>{news.get('full_content', news['content'])}</div>", unsafe_allow_html=True)
        st.divider()

st.markdown("<div class='bottom-safe-space'></div>", unsafe_allow_html=True)














