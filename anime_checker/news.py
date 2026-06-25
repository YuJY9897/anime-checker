import base64
import html
import json
import re
import xml.etree.ElementTree as ET
from datetime import datetime
from email.utils import parsedate_to_datetime
from urllib.parse import parse_qs, quote_plus, unquote, urljoin, urlparse

import requests
import streamlit as st

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
    "RPG", "플레이영상", "플레이 영상", "사전예약", "출시", "업데이트",
    "review", "figure", "merch", "game", "gameplay", "mobile game"
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


def is_news_fallback_candidate(item):
    if not is_schedule_news(item):
        return False
    return is_korean_article_source(item, item.get("link", ""))


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

    for feed in NEWS_FEEDS:
        if news_elapsed() > 7:
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
        if news_elapsed() > 10:
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
    fallback_items = []
    enriched_titles = {re.sub(r"\W+", "", item["title"].lower()) for item in enriched}
    for item in deduped:
        key = re.sub(r"\W+", "", item["title"].lower())
        if key in enriched_titles:
            continue
        if not is_news_fallback_candidate(item):
            continue
        item.pop("_description_raw", None)
        item.pop("_summary", None)
        item["img_bytes"] = b""
        if not is_probable_article_link(item.get("link", "")):
            item["link"] = ""
        fallback_items.append(item)
        if len(enriched) + len(fallback_items) >= max_items:
            break

    if enriched or fallback_items:
        return (enriched + fallback_items)[:max_items]

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

