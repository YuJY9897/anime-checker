import streamlit as st


def render_news_menu(news_data, loaded_label, render_image, on_open):
    st.subheader("최신 애니 소식")
    st.markdown(f"<div class='library-count section-timestamp'>{loaded_label}</div>", unsafe_allow_html=True)
    st.write("방영 예정, 신작 공개일, 시즌 발표 중심의 소식을 확인하세요.")
    st.divider()

    for idx, news in enumerate(news_data):
        with st.container(border=True):
            render_image(news)
            if st.button(news["title"], key=f"news_open_{idx}", use_container_width=True):
                on_open(news)
            st.caption(news["content"])
            if news.get("source"):
                st.caption(f"출처: {news['source']}")
            st.markdown(f"<div class='news-date'>{news['date']}</div>", unsafe_allow_html=True)
