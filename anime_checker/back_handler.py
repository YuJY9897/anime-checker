PARENT_BACK_HANDLER_JS = r"""
(function () {
    const handlerVersion = 17;
    const guardKey = "__animeCheckerBackGuardInstalledV17";
    const listenerKey = "__animeCheckerBackPopHandlerV17";
    const hashGuardKey = "__animeCheckerHashGuardUntil";
    const lastBackKey = "__animeCheckerLastBackAt";
    const suppressExitUntilKey = "__animeCheckerSuppressExitUntil";
    const delayMs = 1800;

    window.__animeCheckerBackHandlerVersion = handlerVersion;
    document.documentElement.setAttribute("data-anime-back-handler-version", String(handlerVersion));

    function normalizeState(state) {
        state = state || {};
        return {
            view: state.view || "main",
            selectedSeason: state.selectedSeason || "none",
            mainSection: state.mainSection || "새 화"
        };
    }

    function getCurrentAppState() {
        const marker = document.getElementById("anime-current-view");
        if (marker) {
            return normalizeState({
                view: marker.getAttribute("data-view") || "main",
                selectedSeason: marker.getAttribute("data-selected-season") || "none",
                mainSection: marker.getAttribute("data-main-section") || "새 화"
            });
        }
        if (window.__animeCheckerCurrentView) {
            return normalizeState(window.__animeCheckerCurrentView);
        }
        return normalizeState(window.__animeCheckerCurrentView);
    }

    function refreshHistoryGuard() {
        const guardState = {
            animeCheckerGuard: true,
            animeCheckerVersion: handlerVersion,
            animeCheckerView: getCurrentAppState()
        };
        try {
            window.history.replaceState(guardState, "", window.location.href);
            window.history.pushState(guardState, "", window.location.href);
        } catch (error) {
            try {
                window.history.pushState({ animeCheckerGuard: true }, "", window.location.href);
            } catch (innerError) {}
        }
        try {
            if (!window.location.hash || !window.location.hash.startsWith("#anime-checker-guard-v")) {
                window[hashGuardKey] = Date.now() + 700;
                window.location.hash = "anime-checker-guard-v" + handlerVersion;
            }
        } catch (error) {
        }
    }

    function showBackToast(message) {
        let toast = document.getElementById("anime-back-toast");
        if (!toast) {
            toast = document.createElement("div");
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
            document.body.appendChild(toast);
        }
        toast.textContent = message || "뒤로가기를 한 번 더 누르면 종료됩니다";
        toast.style.opacity = "1";
        window.clearTimeout(window.__animeBackToastTimer);
        window.__animeBackToastTimer = window.setTimeout(function () {
            toast.style.opacity = "0";
        }, 1500);
    }

    function findVisibleAppBackButton() {
        const labels = ["뒤로가기", "목록으로 돌아가기"];
        return Array.from(document.querySelectorAll("button")).find(function (button) {
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
        const url = new URL(window.location.href);
        url.searchParams.set(name, value);
        window.location.href = url.toString();
    }

    function requestAppBack(target) {
        updateUrlParam("app_back", target || "main_root");
    }

    function requestMainSection(label) {
        updateUrlParam("main_nav", label || "새 화");
    }

    function getBackState(event) {
        const currentState = getCurrentAppState();
        const eventState = normalizeState(event && event.state && event.state.animeCheckerView);
        if (currentState.view === "main" && eventState.view !== "main") {
            return eventState;
        }
        return currentState;
    }

    function handleBack(event) {
        if (window.__animeCheckerBackHandlerVersion !== handlerVersion) {
            return;
        }
        if (Date.now() < (window[hashGuardKey] || 0)) {
            return;
        }

        const state = getBackState(event);
        if (state.view !== "main") {
            window[lastBackKey] = 0;
            window[suppressExitUntilKey] = Date.now() + 350;

            if (state.view === "detail") {
                requestAppBack(state.selectedSeason === "selected" ? "season_list" : "main_root");
                return;
            }
            if (state.view === "news_detail") {
                requestAppBack("news_return");
                return;
            }
            if (clickVisibleAppBackButton()) {
                refreshHistoryGuard();
                return;
            }
            requestAppBack("main_root");
            return;
        }

        if ((state.mainSection || "새 화") !== "새 화") {
            window[lastBackKey] = 0;
            window[suppressExitUntilKey] = Date.now() + 350;
            requestMainSection("새 화");
            return;
        }

        const now = Date.now();
        if (now < (window[suppressExitUntilKey] || 0)) {
            window[lastBackKey] = 0;
            refreshHistoryGuard();
            return;
        }
        if (now - (window[lastBackKey] || 0) <= delayMs) {
            window[guardKey] = false;
            window.history.back();
            return;
        }
        window[lastBackKey] = now;
        showBackToast("뒤로가기를 한 번 더 누르면 종료됩니다");
        refreshHistoryGuard();
    }

    try {
        window.history.scrollRestoration = "manual";
    } catch (error) {}
    refreshHistoryGuard();
    if (window[listenerKey]) {
        window.removeEventListener("popstate", window[listenerKey], true);
        window.removeEventListener("hashchange", window[listenerKey], true);
    }
    window[listenerKey] = handleBack;
    window[guardKey] = true;
    window.addEventListener("popstate", handleBack, true);
    window.addEventListener("hashchange", handleBack, true);
    window.onpopstate = handleBack;
})();
"""
