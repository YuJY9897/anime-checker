import html

import streamlit as st


def _card_columns(count):
    if count == 1:
        cols = st.columns([1, 2, 1], gap="small")
        return [cols[1]]
    return st.columns(2, gap="small")


def render_wish_menu(wish_items, is_added, on_add, on_remove):
    st.subheader("찜 목록")
    st.markdown(f"<div class='library-count'>총 {len(wish_items)}개</div>", unsafe_allow_html=True)

    if not wish_items:
        st.write("찜한 애니가 없습니다.")
        return

    for row_start in range(0, len(wish_items), 2):
        row = wish_items[row_start:row_start + 2]
        cols = _card_columns(len(row))
        for offset, item in enumerate(row):
            tv_id = str(item.get("id", ""))
            title = item.get("title", "제목 없음")
            rep_img = item.get("img") or (
                f"https://image.tmdb.org/t/p/w500{item.get('poster_path')}"
                if item.get("poster_path") else ""
            )
            with cols[offset]:
                with st.container(border=True):
                    if rep_img:
                        st.image(rep_img, use_container_width=True)
                    st.markdown(
                        f"<div class='wish-card-title'>{html.escape(title)}</div>",
                        unsafe_allow_html=True,
                    )
                    add_col, remove_col = st.columns(2, gap="small")
                    with add_col:
                        if is_added(title):
                            st.button(
                                "완료",
                                key=f"wish_done_{tv_id}_{row_start}_{offset}",
                                disabled=True,
                                use_container_width=True,
                            )
                        elif st.button(
                            "추가",
                            key=f"wish_add_{tv_id}_{row_start}_{offset}",
                            use_container_width=True,
                        ):
                            on_add(tv_id, title)
                    with remove_col:
                        if st.button(
                            "삭제",
                            key=f"wish_remove_{tv_id}_{row_start}_{offset}",
                            use_container_width=True,
                        ):
                            on_remove(tv_id)
