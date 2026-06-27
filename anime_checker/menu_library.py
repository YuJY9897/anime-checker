import streamlit as st


def _row_columns(count, row_class):
    cols = st.columns(2, gap="small")
    with cols[0]:
        anchor_classes = f"native-two-col-anchor {row_class}"
        if count == 1:
            anchor_classes += " native-two-col-single"
        st.markdown(f"<span class='{anchor_classes}'></span>", unsafe_allow_html=True)
    return [cols[0]] if count == 1 else cols


def render_anime_tile_grid(cards, key_prefix, on_open):
    for row_start in range(0, len(cards), 2):
        row = cards[row_start:row_start + 2]
        cols = _row_columns(len(row), "library-native-row")
        for offset, card in enumerate(row):
            title = card["title"]
            label = f"{title} N" if card.get("needs_n_badge") else title
            with cols[offset]:
                if st.button(
                    label,
                    key=f"{key_prefix}_{card['uid']}_{row_start}_{offset}",
                    use_container_width=True,
                ):
                    on_open(title)


def build_tile_cards(cards, get_uid):
    return [
        {
            "title": card["title"],
            "uid": get_uid(card["title"], card["info"]),
            "needs_n_badge": card.get("needs_n_badge", False),
        }
        for card in cards
    ]
