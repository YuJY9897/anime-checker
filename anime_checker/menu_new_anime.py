import html

import streamlit as st


def _row_columns(count):
    cols = st.columns(2, gap="small")
    with cols[0]:
        anchor_classes = "native-two-col-anchor new-anime-native-row"
        if count == 1:
            anchor_classes += " native-two-col-single"
        st.markdown(f"<span class='{anchor_classes}'></span>", unsafe_allow_html=True)
    return [cols[0]] if count == 1 else cols


def _action_columns():
    cols = st.columns(2, gap="small")
    with cols[0]:
        st.markdown("<span class='native-action-row-anchor'></span>", unsafe_allow_html=True)
    return cols


def render_new_anime_menu(
    animes,
    loaded_label,
    genre_name_for_id,
    format_air_date,
    is_wished,
    is_added,
    on_wish,
    on_add,
):
    st.subheader("신작 애니")
    st.markdown(f"<div class='library-count section-timestamp'>{loaded_label}</div>", unsafe_allow_html=True)
    st.write("한국 OTT에서 서비스 중이거나 서비스 예정인 애니메이션을 최신순으로 확인하세요.")
    st.divider()

    if not animes:
        st.write("한국 OTT 서비스 기준 신작 애니 정보를 불러오지 못했습니다.")
        return

    for row_start in range(0, len(animes), 2):
        row = animes[row_start:row_start + 2]
        cols = _row_columns(len(row))
        for offset, item in enumerate(row):
            title = item["name"]
            tv_id = item["id"]
            poster_path = item.get("poster_path")
            rep_img = f"https://image.tmdb.org/t/p/w500{poster_path}" if poster_path else ""
            genre_names = [genre_name_for_id(gid) for gid in item.get("genre_ids", [])]
            genre_str = ", ".join(g for g in genre_names if g) or "애니메이션"
            with cols[offset]:
                with st.container(border=True):
                    if rep_img:
                        st.image(rep_img, use_container_width=True)
                    st.markdown(
                        f"<div class='new-anime-card-title'>{html.escape(title)}</div>",
                        unsafe_allow_html=True,
                    )
                    st.markdown(
                        f"<div class='new-anime-card-meta'>장르: {html.escape(genre_str)}</div>",
                        unsafe_allow_html=True,
                    )
                    st.markdown(
                        f"<div class='new-anime-card-meta'>{html.escape(format_air_date(item.get('first_air_date', '')))}</div>",
                        unsafe_allow_html=True,
                    )
                    wish_col, add_col = _action_columns()
                    with wish_col:
                        wish_label = "찜해제" if is_wished(tv_id) else "찜"
                        if st.button(
                            wish_label,
                            key=f"new_wish_{tv_id}_{row_start}_{offset}",
                            use_container_width=True,
                        ):
                            on_wish(tv_id, title, item)
                    with add_col:
                        add_label = "완료" if is_added(title) else "추가"
                        if st.button(
                            add_label,
                            key=f"new_add_{tv_id}_{row_start}_{offset}",
                            disabled=is_added(title),
                            use_container_width=True,
                        ):
                            on_add(tv_id, title)
