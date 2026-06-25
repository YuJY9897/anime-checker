PARENT_BACK_HANDLER_JS = r"""
(function () {
    const handlerVersion = 11;
    const guardKey = "__animeCheckerBackGuardInstalledV11";
    const lastBackKey = "__animeCheckerLastBackAt";
    const suppressExitUntilKey = "__animeCheckerSuppressExitUntil";
    const delayMs = 1800;

    window.__animeCheckerBackHandlerVersion = handlerVersion;
    document.documentElement.setAttribute("data-anime-back-handler-version", String(handlerVersion));

    function getCurrentAppState() {
        if (window.__animeCheckerCurrentView) {
            return window.__animeCheckerCurrentView;
        }
        const marker = document.getElementById("anime-current-view");
        if (marker) {
            return {
                view: marker.getAttribute("data-view") || "main",
                selectedSeason: marker.getAttribute("data-selected-season") || "none",
                mainSection: marker.getAttribute("data-main-section") || "새 화"
            };
        }
        return window.__animeCheckerCurrentView || { view: "main", selectedSeason: "none", mainSection: "새 화" };
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
            window.history.pushState({ animeCheckerGuard: true }, "", window.location.href);
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

    function handleBack(event) {
        if (window.__animeCheckerBackHandlerVersion !== handlerVersion) {
            return;
        }

        const state = (event && event.state && event.state.animeCheckerView) || getCurrentAppState();
        if (state.view !== "main") {
            window[lastBackKey] = 0;
            window[suppressExitUntilKey] = Date.now() + delayMs + 1200;

            if (state.view === "detail" && state.selectedSeason === "selected") {
                requestAppBack("season_list");
                return;
            }

            if (clickVisibleAppBackButton()) {
                refreshHistoryGuard();
                return;
            }

            if (state.view === "detail") {
                requestAppBack(state.selectedSeason === "selected" ? "season_list" : "main_root");
                return;
            }
            if (state.view === "news_detail") {
                requestAppBack("news_return");
                return;
            }
            requestAppBack("main_root");
            return;
        }

        if ((state.mainSection || "새 화") !== "새 화") {
            window[lastBackKey] = 0;
            window[suppressExitUntilKey] = Date.now() + delayMs + 800;
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

    refreshHistoryGuard();
    if (!window[guardKey]) {
        window[guardKey] = true;
        window.addEventListener("popstate", handleBack);
    }
})();
"""
