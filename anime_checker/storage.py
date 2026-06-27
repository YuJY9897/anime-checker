import json
from datetime import datetime


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


def load_app_data_file(data_file):
    empty_data = {"my_anime_list": {}, "watched_db": {}, "wish_list": {}, "updated_at": ""}
    if not data_file.exists():
        return empty_data
    try:
        with data_file.open("r", encoding="utf-8-sig") as f:
            data = json.load(f)
        return normalize_app_data(data) or empty_data
    except (json.JSONDecodeError, OSError):
        return empty_data


def build_app_data(my_anime_list, watched_db, wish_list):
    return {
        "my_anime_list": my_anime_list,
        "watched_db": watched_db,
        "wish_list": wish_list,
        "updated_at": datetime.now().isoformat(timespec="seconds"),
    }


def save_app_data_file(data_file, data):
    tmp_file = data_file.with_suffix(".tmp")
    with tmp_file.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    tmp_file.replace(data_file)


def build_backup_json_text(data):
    return json.dumps(data, ensure_ascii=False, indent=2)
