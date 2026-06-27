import html
from urllib.parse import quote


NEW_ANIME_NAV = quote("신작 애니", safe="")
WISH_NAV = quote("찜", safe="")
TWO_COL_GRID_STYLE = (
    "display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px;"
    "align-items:stretch;justify-content:center;width:100%;"
)
ODD_LAST_CARD_STYLE = "grid-column:1/-1;justify-self:center;width:calc((100% - 8px)/2);"
LIBRARY_CARD_STYLE = (
    "display:flex;min-width:0;min-height:48px;align-items:center;justify-content:center;"
    "padding:7px 8px;border:1px solid #d8e0eb;border-radius:8px;background:#fff;"
    "color:#121826;box-shadow:0 3px 10px rgba(18,24,38,.04);"
    "text-align:center;text-decoration:none;"
)
LIBRARY_TITLE_STYLE = (
    "display:-webkit-box;overflow:hidden;-webkit-box-orient:vertical;-webkit-line-clamp:2;"
    "font-size:13px;font-weight:900;line-height:1.28;color:#121826;"
    "word-break:keep-all;overflow-wrap:anywhere;text-decoration:none;"
)
WISH_CARD_STYLE = (
    "min-width:0;padding:8px;border:1px solid rgba(18,24,38,.12);border-radius:8px;"
    "background:#fff;box-shadow:0 4px 12px rgba(18,24,38,.05);"
)
WISH_IMAGE_STYLE = (
    "display:block;width:100%;height:126px;border-radius:6px;"
    "object-fit:cover;object-position:center;"
)
WISH_TITLE_STYLE = (
    "display:-webkit-box;min-height:2.54em;margin:6px 0;overflow:hidden;"
    "-webkit-box-orient:vertical;-webkit-line-clamp:2;color:#121826;font-size:13px;"
    "font-weight:900;line-height:1.27;text-align:center;word-break:keep-all;"
    "overflow-wrap:anywhere;"
)
ACTION_GRID_STYLE = "display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:5px;"
ACTION_STYLE = (
    "display:flex;align-items:center;justify-content:center;min-height:30px;padding:4px 6px;"
    "border:1px solid #d8e0eb;border-radius:7px;background:#fff;color:#1f2937;"
    "font-size:12px;font-weight:900;line-height:1.25;text-align:center;"
    "text-decoration:none;word-break:keep-all;overflow-wrap:anywhere;"
)
PRIMARY_ACTION_STYLE = ACTION_STYLE + "border-color:#93b7f7;background:#eff6ff;color:#0f3f8c;"


def _odd_card_style(index, total_count):
    return ODD_LAST_CARD_STYLE if total_count % 2 == 1 and index == total_count - 1 else ""


def article_link_html(url):
    if not url:
        return ""
    return (
        f"<a class='article-link-button' href='{html.escape(url, quote=True)}' "
        f"style='{PRIMARY_ACTION_STYLE}width:100%;margin:4px 0 9px;'>원문 기사 보기</a>"
    )


def news_title_link_html(index, title):
    return (
        f"<a class='news-title-link' href='?open_news={index}' "
        f"style='{ACTION_STYLE}justify-content:flex-start;width:100%;min-height:38px;"
        "margin-top:7px;padding:7px 9px;font-size:14px;text-align:left;'>"
        f"{html.escape(title)}</a>"
    )


def library_tile_grid_html(cards, extra_class=""):
    rendered_cards = []
    total_count = len(cards)
    for index, card in enumerate(cards):
        title = card["title"]
        anime_uid = card["uid"]
        badge_html = "<span class='library-tile-badge'>N</span>" if card.get("needs_n_badge") else ""
        meta_text = card.get("meta", "")
        meta_html = f"<div class='library-tile-meta'>{html.escape(meta_text)}</div>" if meta_text else ""
        card_style = LIBRARY_CARD_STYLE + _odd_card_style(index, total_count)
        rendered_cards.append(
            f"<a class='library-tile-card {html.escape(extra_class)}' "
            f"style='{card_style}' href='?open_anime={quote(str(anime_uid), safe='')}'>"
            f"<span class='library-tile-title' style='{LIBRARY_TITLE_STYLE}'>{html.escape(title)} {badge_html}</span>"
            f"{meta_html}</a>"
        )
    return f"<div class='library-tile-grid' style='{TWO_COL_GRID_STYLE}'>{''.join(rendered_cards)}</div>"


def wish_card_grid_html(wish_items):
    cards = []
    total_count = len(wish_items)
    for index, item in enumerate(wish_items):
        tv_id = str(item.get("id", ""))
        title = item.get("title", "제목 없음")
        rep_img = item.get("img", "")
        image_html = f"<img src='{html.escape(rep_img, quote=True)}' alt='' style='{WISH_IMAGE_STYLE}' />" if rep_img else ""
        if item.get("is_added"):
            add_html = f"<span class='wish-card-action disabled' style='{ACTION_STYLE}color:#94a3b8;background:#f8fafc;'>완료</span>"
        else:
            add_html = (
                f"<a class='wish-card-action primary' href='?main_nav={WISH_NAV}&amp;wish_action=add&amp;wish_id={quote(tv_id, safe='')}' "
                f"style='{PRIMARY_ACTION_STYLE}'>추가</a>"
            )
        card_style = WISH_CARD_STYLE + _odd_card_style(index, total_count)
        cards.append(
            f"<article class='wish-card' style='{card_style}'>{image_html}"
            f"<div class='wish-card-title' style='{WISH_TITLE_STYLE}'>{html.escape(title)}</div>"
            f"<div class='wish-card-actions' style='{ACTION_GRID_STYLE}'>{add_html}"
            f"<a class='wish-card-action' href='?main_nav={WISH_NAV}&amp;wish_action=remove&amp;wish_id={quote(tv_id, safe='')}' "
            f"style='{ACTION_STYLE}'>삭제</a></div></article>"
        )
    return f"<div class='wish-card-grid' style='{TWO_COL_GRID_STYLE}'>{''.join(cards)}</div>"


def new_anime_grid_html(items):
    cards = []
    total_count = len(items)
    for index, item in enumerate(items):
        title = item["title"]
        tv_id = item["id"]
        rep_img = item.get("img", "")
        poster_html = f"<img src='{html.escape(rep_img, quote=True)}' alt='' style='{WISH_IMAGE_STYLE}' />" if rep_img else ""
        card_style = WISH_CARD_STYLE + _odd_card_style(index, total_count)
        cards.append(
            f"<article class='new-anime-card' style='{card_style}'>{poster_html}"
            f"<div class='new-anime-card-title' style='{WISH_TITLE_STYLE}'>{html.escape(title)}</div>"
            f"<div class='new-anime-card-meta' style='font-size:12px;line-height:1.35;text-align:center;color:#64748b;margin-bottom:3px;'>"
            f"장르: {html.escape(item.get('genre', '애니메이션'))}</div>"
            f"<div class='new-anime-card-meta' style='font-size:12px;line-height:1.35;text-align:center;color:#64748b;margin-bottom:6px;'>"
            f"{html.escape(item.get('air_date_label', '방영일: 정보 없음'))}</div>"
            f"<div class='new-anime-card-actions' style='{ACTION_GRID_STYLE}'>"
            f"<a href='?main_nav={NEW_ANIME_NAV}&amp;new_action=wish&amp;new_id={quote(str(tv_id), safe='')}' style='{ACTION_STYLE}'>{html.escape(item.get('wish_label', '찜'))}</a>"
            f"<a class='new-anime-add-action' href='?main_nav={NEW_ANIME_NAV}&amp;new_action=add&amp;new_id={quote(str(tv_id), safe='')}' "
            f"style='{PRIMARY_ACTION_STYLE}'>{html.escape(item.get('add_label', '추가'))}</a>"
            "</div></article>"
        )
    return f"<div class='new-anime-grid' style='{TWO_COL_GRID_STYLE}'>{''.join(cards)}</div>"
