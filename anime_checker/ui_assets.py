APP_CSS = """
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
    div[data-testid="stVerticalBlock"] { gap: 0.5rem !important; }
    div[data-testid="stHorizontalBlock"] { gap: 0.48rem !important; }
    div[data-testid="stVerticalBlockBorderWrapper"] { padding: 0.68rem !important; }
    div[data-testid="stMarkdownContainer"] p { margin-bottom: 0.28rem !important; line-height: 1.45 !important; }
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
    button[data-testid="baseButton-secondary"], .stLinkButton>a { width: auto !important; max-width: 100% !important; justify-content: flex-start; }
    .compact-actions-anchor, .search-actions-anchor, .wish-actions-anchor, .season-actions-anchor, .episode-top-actions-anchor { display: none; }
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
    button[data-testid="baseButton-primary"] { width: auto !important; justify-content: center !important; }
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
        min-height: 2.55em;
        line-height: 1.32em;
        margin-top: 6px;
        margin-bottom: 5px;
        font-size: 0.9rem;
        font-weight: bold;
        word-break: keep-all;
        overflow-wrap: anywhere;
    }
    
    .anime-genre { 
        color: #666666; 
        font-size: 0.75em; 
        margin-bottom: 6px; 
        line-height: 1.45;
        white-space: normal; 
        overflow: hidden; 
        text-overflow: ellipsis; 
    }
    
    .date-text { display: flex; align-items: center; justify-content: flex-start; height: 100%; color: gray; font-size: 0.85em; }
    .news-date { color: gray; font-size: 0.8em; text-align: right; margin-top: 3px; }
    .anime-date { color: gray; font-size: 0.75em; margin-top: 2px; margin-bottom: 8px; line-height: 1.45; }
    .search-hint { color: #888888; font-size: 0.78em; text-align: left; margin-top: -12px; margin-bottom: 6px; }
    .library-count {
        color: #8a8f98; font-size: 0.76rem; text-align: right;
        margin-top: -0.2rem; margin-bottom: 0.2rem;
    }
    .detail-meta-text {
        min-width: 0; flex: 1; color: #4b5563; font-size: 0.86rem; line-height: 1.5;
    }
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
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) .stLinkButton > a {
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
    .movie-title {
        display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
        overflow: hidden; text-overflow: ellipsis; min-height: 2.5em;
        line-height: 1.34; font-size: 0.92rem; font-weight: 700; color: #31333F;
        margin: 4px 0 4px 0; word-break: keep-all; overflow-wrap: anywhere;
    }
    .movie-meta {
        color: #6b7280; font-size: 0.74rem; line-height: 1.42;
        margin-bottom: 6px; word-break: keep-all; overflow-wrap: anywhere;
    }
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
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) .stLinkButton > a {
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
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) .stLinkButton > a {
        width: auto !important; max-width: 58px !important; min-width: 42px !important;
        height: 28px !important; min-height: 28px !important; padding: 0 8px !important;
        font-size: 0.78rem !important; justify-content: center !important;
    }
    .episode-main { min-width: 0; flex: 1; }
    .episode-title { font-size: 0.95rem; line-height: 1.38; font-weight: 700; color: #31333F; }
    .episode-date { margin-top: 4px; font-size: 0.78rem; line-height: 1.35; color: #6b7280; }
    .episode-actions { flex-shrink: 0; display: flex; align-items: center; justify-content: flex-end; }
    .episode-actions [data-testid="stButton"] button {
        width: auto !important; max-width: 48px !important; min-width: 42px !important;
        height: 28px !important; min-height: 28px !important;
        padding: 0 8px !important; font-size: 0.78rem !important;
        justify-content: center !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-main) {
        display: flex !important; flex-direction: row !important; align-items: center !important; gap: 10px !important;
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
        height: 1px; background: #eef0f3; margin: 8px 0;
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
    div[data-testid="stVerticalBlock"] { gap: 0.5rem !important; }
    div[data-testid="stHorizontalBlock"] { gap: 0.48rem !important; }
    div[data-testid="stVerticalBlockBorderWrapper"] {
        border: 1px solid #e6e8ee !important;
        border-radius: 12px !important;
        background: #ffffff !important;
        padding: 0.72rem !important;
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
        padding: 0.42rem 0.72rem !important;
        min-height: 34px !important;
        white-space: nowrap !important;
        font-size: 0.83rem !important;
        font-weight: 800 !important;
        line-height: 1.25 !important;
    }
    div[data-testid="stTabs"] button[aria-selected="true"] {
        background: #e8f1ff !important;
        color: #0f3f8c !important;
        border-color: #93b7f7 !important;
        box-shadow: inset 0 0 0 1px rgba(37, 99, 235, 0.16) !important;
    }
    div[data-testid="stTabs"] button[role="tab"] p,
    div[data-testid="stTabs"] button[role="tab"] span { color: inherit !important; line-height: 1.25 !important; }
    div[data-testid="stTabs"] button[aria-selected="true"] p,
    div[data-testid="stTabs"] button[aria-selected="true"] span { color: #0f3f8c !important; }
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
        line-height: 1.25 !important;
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
    .anime-title { font-size: 0.86rem !important; min-height: 2.55em !important; line-height: 1.32 !important; margin-bottom: 5px !important; }
    .anime-genre { color: #6b7280 !important; line-height: 1.45 !important; margin-bottom: 6px !important; white-space: normal !important; }
    .anime-date, .movie-meta, .episode-date { color: #6b7280 !important; line-height: 1.4 !important; }
    .movie-title { line-height: 1.34 !important; min-height: 2.68em !important; margin-bottom: 4px !important; }
    .episode-title { line-height: 1.38 !important; }
    .episode-date { margin-top: 4px !important; }
    .episode-row-divider { background: #edf0f5 !important; margin: 8px 0 !important; }
    .news-date, .library-count { color: #7b8290 !important; font-size: 0.74rem !important; line-height: 1.35 !important; }
    div[data-testid="stMarkdownContainer"] p { line-height: 1.45 !important; margin-bottom: 0.28rem !important; }
    .stImage img { height: 124px !important; border-radius: 10px !important; }
    @media (max-width: 430px) {
        div.block-container { padding-left: 0.55rem !important; padding-right: 0.55rem !important; }
        .stImage img { height: 112px !important; }
        .anime-title { font-size: 0.84rem !important; }
        div[data-testid="stTabs"] button[role="tab"] { font-size: 0.8rem !important; padding-left: 0.58rem !important; padding-right: 0.58rem !important; }
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
    div[data-testid="stPills"] div[role="radiogroup"],
    div[data-testid="stPills"] div[role="group"] {
        display: grid !important;
        grid-template-columns: repeat(3, minmax(0, 1fr)) !important;
        gap: 6px !important;
        align-items: stretch !important;
        width: 100% !important;
    }
    div[data-testid="stPills"] label,
    div[data-testid="stPills"] button {
        width: 100% !important;
        min-width: 0 !important;
        max-width: none !important;
        border-radius: 999px !important;
        min-height: 30px !important;
        padding: 3px 9px !important;
        font-size: 0.78rem !important;
        font-weight: 800 !important;
        white-space: nowrap !important;
        justify-content: center !important;
    }
    .st-key-main_section_pills div[role="radiogroup"],
    div[data-testid="stButtonGroup"] div[role="radiogroup"] {
        display: grid !important;
        grid-template-columns: repeat(3, minmax(0, 1fr)) !important;
        gap: 6px !important;
        width: 100% !important;
    }
    .st-key-main_section_pills button[data-testid^="stBaseButton-pills"],
    div[data-testid="stButtonGroup"] button[data-testid^="stBaseButton-pills"] {
        width: 100% !important;
        min-width: 0 !important;
        max-width: none !important;
        justify-content: center !important;
        text-align: center !important;
        white-space: nowrap !important;
    }

    html, body, [data-testid="stAppViewContainer"], div.block-container {
        overflow-x: hidden !important;
    }
    div[data-testid="column"] {
        min-width: 0 !important;
    }
    .stButton, .stDownloadButton, .stLinkButton {
        max-width: 100% !important;
    }
    .stButton > button, .stDownloadButton > button, .stLinkButton > a {
        box-sizing: border-box !important;
    }

    div[data-testid="stHorizontalBlock"]:has(.search-actions-anchor),
    div[data-testid="stHorizontalBlock"]:has(.wish-actions-anchor),
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor),
    div[data-testid="stHorizontalBlock"]:has(.season-actions-anchor),
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor),
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor),
    div[data-testid="stHorizontalBlock"]:has(.library-title-actions-anchor) {
        display: grid !important;
        grid-template-columns: minmax(0, 1fr) max-content max-content !important;
        align-items: center !important;
        gap: 6px !important;
        flex-wrap: nowrap !important;
        width: 100% !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.library-title-actions-anchor),
    div[data-testid="stHorizontalBlock"]:has(.season-actions-anchor),
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) {
        grid-template-columns: minmax(0, 1fr) max-content !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.search-actions-anchor) > div,
    div[data-testid="stHorizontalBlock"]:has(.wish-actions-anchor) > div,
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) > div,
    div[data-testid="stHorizontalBlock"]:has(.season-actions-anchor) > div,
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) > div,
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) > div,
    div[data-testid="stHorizontalBlock"]:has(.library-title-actions-anchor) > div {
        flex: none !important;
        width: auto !important;
        min-width: 0 !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.search-actions-anchor) > div:first-child,
    div[data-testid="stHorizontalBlock"]:has(.wish-actions-anchor) > div:first-child,
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) > div:first-child,
    div[data-testid="stHorizontalBlock"]:has(.season-actions-anchor) > div:first-child,
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) > div:first-child,
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) > div:first-child,
    div[data-testid="stHorizontalBlock"]:has(.library-title-actions-anchor) > div:first-child {
        justify-self: stretch !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.search-actions-anchor) > div:not(:first-child),
    div[data-testid="stHorizontalBlock"]:has(.wish-actions-anchor) > div:not(:first-child),
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) > div:not(:first-child),
    div[data-testid="stHorizontalBlock"]:has(.season-actions-anchor) > div:not(:first-child),
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) > div:not(:first-child),
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) > div:not(:first-child),
    div[data-testid="stHorizontalBlock"]:has(.library-title-actions-anchor) > div:not(:first-child) {
        justify-self: end !important;
        width: max-content !important;
        min-width: 0 !important;
        max-width: none !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.search-actions-anchor) [data-testid="stButton"],
    div[data-testid="stHorizontalBlock"]:has(.wish-actions-anchor) [data-testid="stButton"],
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) [data-testid="stButton"],
    div[data-testid="stHorizontalBlock"]:has(.season-actions-anchor) [data-testid="stButton"],
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) [data-testid="stButton"],
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) [data-testid="stButton"],
    div[data-testid="stHorizontalBlock"]:has(.library-title-actions-anchor) [data-testid="stButton"] {
        width: auto !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.search-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.wish-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.new-anime-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.season-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.movie-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) [data-testid="stButton"] button,
    div[data-testid="stHorizontalBlock"]:has(.library-title-actions-anchor) [data-testid="stButton"] button {
        width: max-content !important;
        max-width: none !important;
        min-width: 42px !important;
        height: 28px !important;
        min-height: 28px !important;
        padding: 0 8px !important;
        justify-content: center !important;
        text-align: center !important;
        white-space: nowrap !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-main) {
        display: grid !important;
        grid-template-columns: minmax(0, 1fr) max-content !important;
        align-items: center !important;
        gap: 10px !important;
        width: 100% !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-main) > div {
        flex: none !important;
        width: auto !important;
        min-width: 0 !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-main) > div:last-child {
        justify-self: end !important;
        width: max-content !important;
        min-width: 0 !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-main) [data-testid="stButton"] button {
        width: max-content !important;
        max-width: none !important;
        min-width: 44px !important;
        white-space: nowrap !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-top-actions-anchor) {
        display: grid !important;
        grid-template-columns: minmax(0, 1fr) minmax(0, 1fr) !important;
        align-items: center !important;
        gap: 6px !important;
        width: 100% !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-top-actions-anchor) > div {
        flex: none !important;
        width: auto !important;
        min-width: 0 !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-top-actions-anchor) [data-testid="stButton"] button {
        width: 100% !important;
        max-width: 100% !important;
        justify-content: center !important;
        text-align: center !important;
        white-space: nowrap !important;
    }
    div[data-testid="stTabs"] button[role="tab"] {
        background: #eceff3 !important;
        border: 1px solid transparent !important;
        color: #4b5563 !important;
        min-height: 34px !important;
        line-height: 1.25 !important;
    }
    div[data-testid="stTabs"] button[role="tab"] p,
    div[data-testid="stTabs"] button[role="tab"] span {
        color: inherit !important;
        line-height: 1.25 !important;
    }
    div[data-testid="stTabs"] button[role="tab"][aria-selected="true"] {
        background: #e8f1ff !important;
        border-color: #93b7f7 !important;
        color: #0f3f8c !important;
        box-shadow: inset 0 0 0 1px rgba(37, 99, 235, 0.16) !important;
    }
    div[data-testid="stTabs"] button[role="tab"][aria-selected="true"] p,
    div[data-testid="stTabs"] button[role="tab"][aria-selected="true"] span {
        color: #0f3f8c !important;
    }
    div[data-testid="stPills"] button,
    .st-key-main_section_pills button[data-testid^="stBaseButton-pills"],
    div[data-testid="stButtonGroup"] button[data-testid^="stBaseButton-pills"] {
        background: #eef1f5 !important;
        border: 1px solid #d9dee8 !important;
        color: #374151 !important;
    }
    div[data-testid="stPills"] button p,
    .st-key-main_section_pills button[data-testid^="stBaseButton-pills"] p,
    div[data-testid="stButtonGroup"] button[data-testid^="stBaseButton-pills"] p {
        color: #374151 !important;
    }
    div[data-testid="stPills"] button[aria-selected="true"],
    .st-key-main_section_pills button[data-testid^="stBaseButton-pills"][aria-selected="true"],
    div[data-testid="stButtonGroup"] button[data-testid^="stBaseButton-pills"][aria-selected="true"] {
        background: #e8f1ff !important;
        border-color: #93b7f7 !important;
        color: #0f3f8c !important;
    }
    div[data-testid="stPills"] button[aria-selected="true"] p,
    .st-key-main_section_pills button[data-testid^="stBaseButton-pills"][aria-selected="true"] p,
    div[data-testid="stButtonGroup"] button[data-testid^="stBaseButton-pills"][aria-selected="true"] p {
        color: #0f3f8c !important;
    }

    /* === Store-grade mobile visual system === */
    :root {
        --app-bg: #f4f6f8;
        --surface: #ffffff;
        --surface-soft: #f8fafc;
        --ink: #121826;
        --muted: #667085;
        --line: #dfe4ec;
        --blue: #2563eb;
        --blue-soft: #eaf2ff;
        --jade: #0f766e;
        --jade-soft: #e6f7f4;
        --rose: #be123c;
        --rose-soft: #fff1f2;
        --amber: #b45309;
        --amber-soft: #fff7ed;
    }
    html, body, [data-testid="stAppViewContainer"] {
        background: var(--app-bg) !important;
        color: var(--ink) !important;
    }
    [data-testid="stAppViewContainer"] > .main {
        background: var(--app-bg) !important;
    }
    div.block-container {
        max-width: 560px !important;
        padding: 0.55rem 0.72rem 6.75rem !important;
    }
    .app-shell-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
        margin: 0.15rem 0 0.68rem;
        padding: 0.75rem 0.82rem;
        border: 1px solid rgba(18, 24, 38, 0.08);
        border-radius: 8px;
        background:
            linear-gradient(135deg, rgba(37, 99, 235, 0.10), rgba(15, 118, 110, 0.07)),
            var(--surface);
        box-shadow: 0 12px 28px rgba(18, 24, 38, 0.08);
    }
    .app-brand-kicker {
        color: var(--blue);
        font-size: 0.66rem;
        font-weight: 900;
        letter-spacing: 0;
        line-height: 1.1;
    }
    .app-brand-title {
        color: var(--ink);
        font-size: 1.28rem;
        font-weight: 900;
        line-height: 1.18;
        letter-spacing: 0;
        margin-top: 2px;
    }
    .app-brand-date {
        flex: 0 0 auto;
        color: #334155;
        background: rgba(255, 255, 255, 0.74);
        border: 1px solid rgba(18, 24, 38, 0.08);
        border-radius: 999px;
        padding: 0.34rem 0.55rem;
        font-size: 0.76rem;
        font-weight: 800;
        line-height: 1;
    }
    h1, h2, h3 {
        color: var(--ink) !important;
        letter-spacing: 0 !important;
    }
    h1 {
        font-size: 1.38rem !important;
        font-weight: 900 !important;
        line-height: 1.23 !important;
        margin: 0.2rem 0 0.46rem !important;
    }
    h2, h3 {
        font-size: 1.05rem !important;
        font-weight: 900 !important;
        line-height: 1.28 !important;
        margin: 0.36rem 0 0.38rem !important;
    }
    div[data-testid="stForm"] {
        border: 1px solid rgba(18, 24, 38, 0.08) !important;
        border-radius: 8px !important;
        background: var(--surface) !important;
        padding: 0.56rem !important;
        box-shadow: 0 10px 24px rgba(18, 24, 38, 0.06) !important;
    }
    div[data-testid="stForm"] input {
        background: var(--surface-soft) !important;
        border-color: #dbe3ef !important;
        color: var(--ink) !important;
        font-weight: 700 !important;
    }
    div[data-testid="stForm"] input::placeholder {
        color: #8a94a6 !important;
    }
    .search-hint {
        color: var(--muted) !important;
        font-size: 0.76rem !important;
        margin: 0.32rem 0 0.55rem !important;
        padding-left: 0.1rem !important;
    }
    div[data-testid="stPills"] div[role="radiogroup"],
    .st-key-main_section_pills div[role="radiogroup"],
    div[data-testid="stButtonGroup"] div[role="radiogroup"] {
        display: grid !important;
        grid-template-columns: repeat(3, minmax(0, 1fr)) !important;
        gap: 7px !important;
        width: 100% !important;
        padding: 0.2rem 0 0.46rem !important;
    }
    div[data-testid="stPills"] button,
    .st-key-main_section_pills button[data-testid^="stBaseButton-pills"],
    div[data-testid="stButtonGroup"] button[data-testid^="stBaseButton-pills"] {
        width: 100% !important;
        min-height: 34px !important;
        border-radius: 8px !important;
        border: 1px solid #dbe2ec !important;
        background: #ffffff !important;
        color: #334155 !important;
        box-shadow: 0 1px 2px rgba(18, 24, 38, 0.04) !important;
        font-size: 0.78rem !important;
        font-weight: 900 !important;
        white-space: nowrap !important;
        justify-content: center !important;
    }
    div[data-testid="stPills"] button p,
    .st-key-main_section_pills button[data-testid^="stBaseButton-pills"] p,
    div[data-testid="stButtonGroup"] button[data-testid^="stBaseButton-pills"] p {
        color: inherit !important;
        line-height: 1.12 !important;
    }
    div[data-testid="stPills"] button[aria-selected="true"],
    div[data-testid="stPills"] button[data-testid="stBaseButton-pillsActive"],
    .st-key-main_section_pills button[data-testid^="stBaseButton-pills"][aria-selected="true"],
    .st-key-main_section_pills button[data-testid="stBaseButton-pillsActive"],
    div[data-testid="stButtonGroup"] button[data-testid^="stBaseButton-pills"][aria-selected="true"] {
        background: var(--blue-soft) !important;
        border-color: #93b7f7 !important;
        color: #0f3f8c !important;
        box-shadow: inset 0 0 0 1px rgba(37, 99, 235, 0.12), 0 6px 14px rgba(37, 99, 235, 0.12) !important;
    }
    div[data-testid="stVerticalBlockBorderWrapper"] {
        border: 1px solid rgba(18, 24, 38, 0.08) !important;
        border-radius: 8px !important;
        background: var(--surface) !important;
        padding: 0.64rem !important;
        box-shadow: 0 10px 24px rgba(18, 24, 38, 0.07) !important;
        overflow: hidden !important;
    }
    .stImage img {
        width: 100% !important;
        height: 150px !important;
        border-radius: 7px !important;
        object-fit: cover !important;
        background: #e5e7eb !important;
        box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.45) !important;
    }
    .anime-title, .movie-title {
        color: var(--ink) !important;
        font-weight: 900 !important;
        letter-spacing: 0 !important;
    }
    .anime-title {
        font-size: 0.91rem !important;
        line-height: 1.32 !important;
        min-height: 2.6em !important;
        margin: 0.48rem 0 0.28rem !important;
    }
    .anime-genre, .anime-date, .movie-meta, .episode-date, .detail-meta-text {
        color: var(--muted) !important;
        line-height: 1.48 !important;
        word-break: keep-all !important;
        overflow-wrap: anywhere !important;
    }
    .anime-genre {
        font-size: 0.76rem !important;
        margin-bottom: 0.32rem !important;
    }
    .anime-date, .movie-meta {
        font-size: 0.75rem !important;
        margin-bottom: 0.42rem !important;
    }
    .library-count, .news-date {
        color: #6b7280 !important;
        font-size: 0.74rem !important;
        font-weight: 800 !important;
        line-height: 1.3 !important;
    }
    .stButton > button,
    .stDownloadButton > button,
    .stLinkButton > a {
        border-radius: 8px !important;
        border: 1px solid #d8e0eb !important;
        background: #ffffff !important;
        color: #1f2937 !important;
        box-shadow: 0 1px 2px rgba(18, 24, 38, 0.04) !important;
        font-weight: 900 !important;
        letter-spacing: 0 !important;
        transition: border-color 120ms ease, background 120ms ease, box-shadow 120ms ease !important;
    }
    .stButton > button:hover,
    .stDownloadButton > button:hover,
    .stLinkButton > a:hover {
        border-color: #9db2cf !important;
        background: #f8fbff !important;
        box-shadow: 0 6px 16px rgba(18, 24, 38, 0.08) !important;
    }
    button[data-testid="baseButton-primary"],
    button[data-testid="stBaseButton-primary"],
    button[data-testid="stBaseButton-secondaryFormSubmit"],
    div[data-testid="stForm"] button[data-testid="baseButton-secondary"] {
        background: var(--blue) !important;
        border-color: var(--blue) !important;
        color: #ffffff !important;
        box-shadow: 0 8px 18px rgba(37, 99, 235, 0.2) !important;
    }
    button[data-testid="baseButton-primary"] p,
    button[data-testid="stBaseButton-primary"] p,
    button[data-testid="stBaseButton-secondaryFormSubmit"] p,
    div[data-testid="stForm"] button[data-testid="baseButton-secondary"] p {
        color: #ffffff !important;
    }
    div[data-testid="stTabs"] [role="tablist"] {
        gap: 6px !important;
        border-bottom: 0 !important;
        padding-bottom: 0.38rem !important;
    }
    div[data-testid="stTabs"] button[role="tab"] {
        border-radius: 8px !important;
        border: 1px solid #dce3ed !important;
        background: #ffffff !important;
        color: #475569 !important;
        min-height: 34px !important;
        font-size: 0.8rem !important;
        font-weight: 900 !important;
        box-shadow: 0 1px 2px rgba(18, 24, 38, 0.04) !important;
    }
    div[data-testid="stTabs"] button[role="tab"][aria-selected="true"] {
        background: var(--jade-soft) !important;
        border-color: #76c7bb !important;
        color: #075e56 !important;
        box-shadow: inset 0 0 0 1px rgba(15, 118, 110, 0.12), 0 6px 14px rgba(15, 118, 110, 0.12) !important;
    }
    div[data-testid="stTabs"] button[role="tab"] p,
    div[data-testid="stTabs"] button[role="tab"] span,
    div[data-testid="stTabs"] button[role="tab"][aria-selected="true"] p,
    div[data-testid="stTabs"] button[role="tab"][aria-selected="true"] span {
        color: inherit !important;
    }
    .episode-title {
        color: var(--ink) !important;
        font-size: 0.94rem !important;
        font-weight: 900 !important;
        line-height: 1.4 !important;
    }
    .episode-row-divider {
        height: 1px !important;
        background: #e7ecf3 !important;
        margin: 0.58rem 0 !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-main) {
        border-radius: 8px !important;
        padding: 0.24rem 0 !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-watch-done) > div:last-child [data-testid="stButton"] button,
    .watch-done button,
    div[data-testid="stVerticalBlock"]:has(.watch-done) div[data-testid="stButton"] button {
        color: var(--jade) !important;
        border-color: #93d8ce !important;
        background: var(--jade-soft) !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.episode-watch-pending) > div:last-child [data-testid="stButton"] button,
    .watch-pending button,
    div[data-testid="stVerticalBlock"]:has(.watch-pending) div[data-testid="stButton"] button {
        color: #334155 !important;
        border-color: #d8e0eb !important;
        background: #ffffff !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) > div:nth-child(3) [data-testid="stButton"] button {
        color: var(--amber) !important;
        border-color: #fed7aa !important;
        background: var(--amber-soft) !important;
    }
    div[data-testid="stHorizontalBlock"]:has(.detail-actions-anchor) > div:nth-child(4) [data-testid="stButton"] button {
        color: var(--rose) !important;
        border-color: #fecdd3 !important;
        background: var(--rose-soft) !important;
    }
    div[data-testid="stExpander"] details {
        border: 1px solid rgba(18, 24, 38, 0.08) !important;
        border-radius: 8px !important;
        background: #ffffff !important;
        box-shadow: 0 6px 16px rgba(18, 24, 38, 0.05) !important;
    }
    div[data-testid="stExpander"] summary {
        font-weight: 900 !important;
        color: var(--ink) !important;
    }
    div[data-testid="stFileUploader"] {
        border-radius: 8px !important;
    }
    div[data-testid="stAlert"] {
        border-radius: 8px !important;
    }
    .scroll-top-btn {
        border-radius: 999px !important;
        background: #121826 !important;
        box-shadow: 0 10px 22px rgba(18, 24, 38, 0.24) !important;
    }
    @media (max-width: 430px) {
        div.block-container {
            padding-left: 0.58rem !important;
            padding-right: 0.58rem !important;
        }
        .app-shell-header {
            padding: 0.68rem 0.72rem;
            margin-bottom: 0.58rem;
        }
        .app-brand-title {
            font-size: 1.18rem;
        }
        .app-brand-date {
            font-size: 0.7rem;
            padding: 0.3rem 0.46rem;
        }
        .stImage img {
            height: 128px !important;
        }
        .anime-title {
            font-size: 0.86rem !important;
        }
        div[data-testid="stPills"] button,
        .st-key-main_section_pills button[data-testid^="stBaseButton-pills"],
        div[data-testid="stButtonGroup"] button[data-testid^="stBaseButton-pills"] {
            min-height: 32px !important;
            padding-left: 6px !important;
            padding-right: 6px !important;
            font-size: 0.74rem !important;
        }
        .scroll-top-btn {
            display: none !important;
        }
    }
    @media (max-width: 640px) {
        .scroll-top-btn {
            display: none !important;
        }
    }
    div[data-testid="stPills"] button[data-testid="stBaseButton-pillsActive"],
    .st-key-main_section_pills button[data-testid="stBaseButton-pillsActive"],
    div[data-testid="stButtonGroup"] button[data-testid="stBaseButton-pillsActive"] {
        background: var(--blue-soft) !important;
        border-color: #93b7f7 !important;
        color: #0f3f8c !important;
        box-shadow: inset 0 0 0 1px rgba(37, 99, 235, 0.12), 0 6px 14px rgba(37, 99, 235, 0.12) !important;
    }
    div[data-testid="stPills"] button[data-testid="stBaseButton-pillsActive"] p,
    .st-key-main_section_pills button[data-testid="stBaseButton-pillsActive"] p,
    div[data-testid="stButtonGroup"] button[data-testid="stBaseButton-pillsActive"] p {
        color: #0f3f8c !important;
    }
    </style>
"""

SCROLL_TOP_LINK = "<a class='scroll-top-btn' href='#top' title='맨 위로'>↑<span>맨 위</span></a>"
