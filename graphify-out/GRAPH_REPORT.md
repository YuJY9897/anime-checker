# Graph Report - 애니 체크  (2026-11-16)

## Corpus Check
- 97 files · ~380,328 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 35 file(s) not represented in the graph (top: .xml 9, (none) 5, .plist 4)

## Summary
- 1202 nodes · 1652 edges · 77 communities (65 shown, 12 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 10 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `37ba757b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_controller.dart
- index.js
- anime_query.dart
- anime_card.dart
- date_text.dart
- package:flutter_test/flutter_test.dart
- app_data.dart
- watch_stats.dart
- news_screen.dart
- play_upload.mjs
- anime_mutation.dart
- package:flutter/material.dart
- app_logic_test.dart
- AppDelegate
- appControllerProvider
- season_migration.dart
- home_screen.dart
- api_client.dart
- settings_screen.dart
- local_repository.dart
- anime.dart
- sample_data.dart
- legal_screen.dart
- shell_screen.dart
- main_sections.dart
- StatelessWidget
- episode.dart
- detail_screen.dart
- library_screen.dart
- schedule_screen.dart
- 기능 기준
- new_anime_screen.dart
- feedback_screen.dart
- local_repository_test.dart
- manifest.json
- theme.dart
- anime_checker_proxy/package.json
- anime_movie.dart
- anime_season.dart
- patch_notes_screen.dart
- help_screen.dart
- ../data/models/models.dart
- empty_state.dart
- MainActivity.kt
- episode_target.dart
- data_diagnostics.dart
- ConsumerState
- section_header.dart
- _
- backup_summary.dart
- genre_text.dart
- scroll_top_area.dart
- 애니 체크 Play Store 등록 자료
- news_webview_screen.dart
- ambient_background.dart
- 애니 체크 개인정보처리방침
- card_modes_test.dart
- README.md
- 애니 체크 Play Store 등록정보 초안
- 애니 체크 Play Store 출시 체크리스트
- NewsWebViewScreen
- 애니 체크 Play Store 등록 체크리스트
- 애니 체크 Flutter
- 애니 체크 작업 규칙
- progress_bar.dart
- feedback_management.md
- backup_parse_test.dart
- anime_checker_proxy/README.md
- LaunchImage.imageset/README.md
- .claude/CLAUDE.md
- CLAUDE.local.md

## God Nodes (most connected - your core abstractions)
1. `appControllerProvider` - 36 edges
2. `fetch()` - 14 edges
3. `tmdb()` - 13 edges
4. `animeDetail()` - 12 edges
5. `newAnime()` - 12 edges
6. `tmdbNewAnime()` - 10 edges
7. `news()` - 10 edges
8. `toAnimeFromJikan()` - 10 edges
9. `json()` - 10 edges
10. `jikanNewAnime()` - 9 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `appControllerProvider`  [EXTRACTED]
  anime_checker_flutter/lib/src/app.dart → anime_checker_flutter/lib/src/state/app_controller.dart
- `build` --references--> `appControllerProvider`  [EXTRACTED]
  anime_checker_flutter/lib/src/features/backup/backup_screen.dart → anime_checker_flutter/lib/src/state/app_controller.dart
- `build` --references--> `appControllerProvider`  [EXTRACTED]
  anime_checker_flutter/lib/src/features/detail/episode_screen.dart → anime_checker_flutter/lib/src/state/app_controller.dart
- `build` --references--> `appControllerProvider`  [EXTRACTED]
  anime_checker_flutter/lib/src/features/home/home_screen.dart → anime_checker_flutter/lib/src/state/app_controller.dart
- `initState` --references--> `appControllerProvider`  [EXTRACTED]
  anime_checker_flutter/lib/src/features/new_anime/new_anime_screen.dart → anime_checker_flutter/lib/src/state/app_controller.dart

## Import Cycles
- None detected.

## Communities (77 total, 12 thin omitted)

### Community 0 - "app_controller.dart"
Cohesion: 0.02
Nodes (87): addAnime, addWish, addWishToLibrary, allAnime, animeNote, animeStatusLabel, _apiClient, apiClientProvider (+79 more)

### Community 1 - "index.js"
Cohesion: 0.06
Nodes (97): allowFeedback(), animeCompleteness(), animeDetail(), animeDetailResponse(), animeItemDate(), animeItemId(), animeItemTitle(), animeTitleKeys() (+89 more)

### Community 2 - "anime_query.dart"
Cohesion: 0.04
Nodes (56): aDate, airsAroundNow, allAnime, animeNote, animeStatusLabel, base, bDate, bestDate (+48 more)

### Community 3 - "anime_card.dart"
Cohesion: 0.05
Nodes (33): action, _ActionButton, _ActionButtons, actions, AnimeCardAction, build, _buildRow, children (+25 more)

### Community 4 - "date_text.dart"
Cohesion: 0.07
Nodes (27): airDate, animeAiringStatusLabel, animeBroadcastMetaLines, date, formatDotDate, formatNewAnimeAirDate, formatStoredDate, isAnimeCurrentlyAiring (+19 more)

### Community 5 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.09
Nodes (11): main, animeWith, main, storedDate, main, ep, main, season (+3 more)

### Community 6 - "app_data.dart"
Cohesion: 0.10
Nodes (18): animeList, animeNotes, animeSyncedAt, backupVersion, copyWith, dropped, droppedReasons, empty (+10 more)

### Community 7 - "watch_stats.dart"
Cohesion: 0.06
Nodes (28): completionRatio, count, days, droppedAnime, everything, finished, finishedAnime, GenreCount (+20 more)

### Community 8 - "news_screen.dart"
Cohesion: 0.08
Nodes (22): date, fromJson, id, imageUrl, NewsArticle, source, summary, title (+14 more)

### Community 9 - "play_upload.mjs"
Cohesion: 0.09
Nodes (18): googleapis, dependencies, googleapis, name, private, type, androidpublisher, auth (+10 more)

### Community 10 - "anime_mutation.dart"
Cohesion: 0.09
Nodes (21): copyWith, dropped, list, next, notes, reasons, syncedAt, value (+13 more)

### Community 11 - "package:flutter/material.dart"
Cohesion: 0.10
Nodes (11): main, build, _backupAgeText, build, _confirmRestore, controller, _Diagnostics, _Summary (+3 more)

### Community 12 - "app_logic_test.dart"
Cohesion: 0.09
Nodes (17): AnimeApiClient, airingAnime, calls, detail, exportBackup, FakeApiClient, fetchAnime, fetchNewAnime (+9 more)

### Community 13 - "AppDelegate"
Cohesion: 0.11
Nodes (6): AppDelegate, SceneDelegate, RunnerTests, Flutter, UIKit, XCTest

### Community 14 - "appControllerProvider"
Cohesion: 0.15
Nodes (21): AnimeCheckerApp, BackupScreen, build, DetailScreen, EpisodeScreen, HomeScreen, _open, build (+13 more)

### Community 15 - "season_migration.dart"
Cohesion: 0.10
Nodes (19): after, afterCount, before, beforeCount, episodeKey, false, _keysOf, lost (+11 more)

### Community 16 - "home_screen.dart"
Cohesion: 0.12
Nodes (13): build, _confirmDelete, _metaLines, _showAnimeMenu, build, createState, dispose, _searched (+5 more)

### Community 17 - "api_client.dart"
Cohesion: 0.12
Nodes (12): _animeListFrom, _appVersion, baseUrl, _client, fetchAnime, fetchNewAnime, fetchNews, _get (+4 more)

### Community 18 - "settings_screen.dart"
Cohesion: 0.11
Nodes (10): children, _confirmRefreshAll, _confirmReset, controller, icon, label, onChanged, onTap (+2 more)

### Community 19 - "local_repository.dart"
Cohesion: 0.12
Nodes (12): _dataFile, exportBackup, _fileName, load, LocalRepository, parseBackup, _queue, save (+4 more)

### Community 20 - "anime.dart"
Cohesion: 0.12
Nodes (16): copyWith, dropped, firstAirDate, fromJson, genres, id, isMovie, movies (+8 more)

### Community 21 - "sample_data.dart"
Cohesion: 0.14
Nodes (12): _dateOnly, empty, _episodes, generate, _iso, list, now, sampleAnimeList (+4 more)

### Community 22 - "legal_screen.dart"
Cohesion: 0.04
Nodes (42): AppSettings, copyWith, darkMode, defaults, defaultWatchProviders, fromJson, koreanWatchProviders, librarySort (+34 more)

### Community 23 - "shell_screen.dart"
Cohesion: 0.12
Nodes (11): createState, _handleRootBack, initState, lastBackAt, MainSection, MainSectionText, _openSectionMenu, section (+3 more)

### Community 24 - "main_sections.dart"
Cohesion: 0.15
Nodes (3): build, MainSectionBody, section

### Community 25 - "StatelessWidget"
Cohesion: 0.11
Nodes (18): _AppVersionRow, _InfoRow, _OpenRow, _RefreshAllProgress, _SettingsGroup, _StaticRow, _SwitchRow, build (+10 more)

### Community 26 - "episode.dart"
Cohesion: 0.18
Nodes (10): airDate, episodeLabel, fromJson, isPlaceholderEpisodeTitle, number, sourceEpisode, sourceSeason, text (+2 more)

### Community 27 - "detail_screen.dart"
Cohesion: 0.11
Nodes (15): anime, animeId, _buildDetail, _confirmDelete, controller, _editDroppedReason, _editNote, _header (+7 more)

### Community 28 - "library_screen.dart"
Cohesion: 0.18
Nodes (10): _confirmDelete, _editDroppedReason, fromKey, _latestAirDate, LibraryMode, LibrarySort, LibrarySortText, mode (+2 more)

### Community 29 - "schedule_screen.dart"
Cohesion: 0.17
Nodes (9): build, controller, day, _DaySection, items, newEpisodeIds, _orderFromToday, _weekdayOrder (+1 more)

### Community 30 - "기능 기준"
Cohesion: 0.12
Nodes (16): GitHub에 올리면 안 되는 파일, 검증, 기능 기준, 데이터/API, 백업, 보관함, 보류, 새 화 (+8 more)

### Community 31 - "new_anime_screen.dart"
Cohesion: 0.18
Nodes (9): createState, initializedFromSettings, initState, _quarterOf, selectedQuarter, selectedYear, _showMenu, typeFilter (+1 more)

### Community 32 - "feedback_screen.dart"
Cohesion: 0.18
Nodes (10): bodyController, build, categories, category, createState, dispose, emailController, _sendFeedback (+2 more)

### Community 33 - "local_repository_test.dart"
Cohesion: 0.13
Nodes (8): dataFile, dir, _FakePathProvider, getApplicationDocumentsPath, main, oneAnime, PathProviderPlatform, temp

### Community 34 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 36 - "theme.dart"
Cohesion: 0.15
Nodes (12): background, buildAppTheme, card, cardHigh, cardHighest, ink, isDark, muted (+4 more)

### Community 37 - "anime_checker_proxy/package.json"
Cohesion: 0.20
Nodes (9): devDependencies, wrangler, name, private, scripts, deploy, dev, type (+1 more)

### Community 38 - "anime_movie.dart"
Cohesion: 0.22
Nodes (8): AnimeMovie, fromJson, id, posterUrl, releaseDate, runtime, title, toJson

### Community 39 - "anime_season.dart"
Cohesion: 0.22
Nodes (7): episodes, fromJson, name, number, posterUrl, subtitle, toJson

### Community 40 - "patch_notes_screen.dart"
Cohesion: 0.20
Nodes (8): PatchNote, build, isLatest, note, PatchNoteItems, PatchNotesScreen, _PatchNoteTile, showPatchNoteDialog

### Community 41 - "help_screen.dart"
Cohesion: 0.22
Nodes (7): body, build, _HelpItem, _helpItems, HelpScreen, icon, title

### Community 42 - "../data/models/models.dart"
Cohesion: 0.12
Nodes (13): AnimeSeason, anime, build, _isUnaired, season, _setWatched, difference, last (+5 more)

### Community 43 - "empty_state.dart"
Cohesion: 0.22
Nodes (7): actionLabel, build, EmptyState, icon, message, onAction, title

### Community 45 - "episode_target.dart"
Cohesion: 0.22
Nodes (6): Anime, Episode, anime, episode, EpisodeTarget, season

### Community 46 - "data_diagnostics.dart"
Cohesion: 0.25
Nodes (7): DataDiagnostics, dropped, noGenre, noPoster, noSeason, notes, total

### Community 47 - "ConsumerState"
Cohesion: 0.27
Nodes (8): NewAnimeScreen, _NewAnimeScreenState, SearchScreen, _SearchScreenState, FeedbackScreen, _FeedbackScreenState, ShellScreen, _ShellScreenState

### Community 48 - "section_header.dart"
Cohesion: 0.25
Nodes (5): action, build, meta, SectionHeader, title

### Community 49 - "_"
Cohesion: 0.33
Nodes (4): _, _channel, ExternalLinks, open

### Community 50 - "backup_summary.dart"
Cohesion: 0.33
Nodes (5): BackupSummary, dropped, total, watched, wish

### Community 51 - "genre_text.dart"
Cohesion: 0.18
Nodes (9): genre, _genreLabel, _genreLabels, genres, hasUsefulText, _hiddenGenres, normalized, _unknownValues (+1 more)

### Community 57 - "scroll_top_area.dart"
Cohesion: 0.22
Nodes (9): build, _controller, createState, dispose, initState, _onScroll, ScrollTopArea, _ScrollTopAreaState (+1 more)

### Community 58 - "애니 체크 Play Store 등록 자료"
Cohesion: 0.20
Nodes (9): Data Safety 입력 가이드, 기본 정보, 긴 설명, 등록 전에 직접 해야 하는 항목, 릴리스 노트, 비공개 테스트 안내문, 애니 체크 Play Store 등록 자료, 앱 콘텐츠 답변 메모 (+1 more)

### Community 59 - "news_webview_screen.dart"
Cohesion: 0.22
Nodes (6): build, controller, createState, initState, title, url

### Community 60 - "ambient_background.dart"
Cohesion: 0.22
Nodes (7): AmbientBackground, build, child, color, _Glow, size, strength

### Community 61 - "애니 체크 개인정보처리방침"
Cohesion: 0.22
Nodes (8): 1. 수집하는 정보, 2. 저장 방식, 3. 네트워크 사용, 4. 제3자 제공, 5. 삭제, 6. 데이터 출처, 7. 문의, 애니 체크 개인정보처리방침

### Community 62 - "card_modes_test.dart"
Cohesion: 0.25
Nodes (3): main, _usePhoneSurface, _wrap

### Community 63 - "README.md"
Cohesion: 0.25
Nodes (7): Worker 배포, 검증, 구성, 민감 정보, 실행, 주요 기능, 직접 해결한 것

### Community 64 - "애니 체크 Play Store 등록정보 초안"
Cohesion: 0.29
Nodes (6): 긴 설명, 스크린샷 추천 순서, 애니 체크 Play Store 등록정보 초안, 앱 이름, 짧은 설명, 태그 후보

### Community 65 - "애니 체크 Play Store 출시 체크리스트"
Cohesion: 0.29
Nodes (6): AI/규제 체크, Android 빌드, Data safety 초안, Play Console, 애니 체크 Play Store 출시 체크리스트, 저작권 및 출처

### Community 66 - "NewsWebViewScreen"
Cohesion: 0.40
Nodes (4): NewsWebViewScreen, _NewsWebViewScreenState, AnimePosterCard, _AnimePosterCardState

### Community 67 - "애니 체크 Play Store 등록 체크리스트"
Cohesion: 0.33
Nodes (5): Play Console 입력, 빌드/서명, 애니 체크 Play Store 등록 체크리스트, 정책/저작권, 출시 전 수동 확인

### Community 68 - "애니 체크 Flutter"
Cohesion: 0.33
Nodes (5): 검증, 구조, 실행, 애니 체크 Flutter, 제외 범위

### Community 69 - "애니 체크 작업 규칙"
Cohesion: 0.33
Nodes (5): 기능을 바꿨으면 문서도 같이 바꾼다, 배포, 애니 체크 작업 규칙, 특히 놓치기 쉬운 것, 확인 습관

### Community 70 - "progress_bar.dart"
Cohesion: 0.40
Nodes (4): build, GradientProgressBar, height, value

### Community 71 - "feedback_management.md"
Cohesion: 0.40
Nodes (4): 저장되는 값, 처리한 피드백 삭제, 피드백 내용 보기, 피드백 목록 보기

## Knowledge Gaps
- **626 isolated node(s):** `XCTest`, `main`, `trimmed`, `parsed`, `normalized` (+621 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 840 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Anime` connect `episode_target.dart` to `../data/models/models.dart`, `detail_screen.dart`, `anime.dart`, `app_logic_test.dart`?**
  _High betweenness centrality (0.028) - this node is a cross-community bridge._
- **What connects `XCTest`, `main`, `trimmed` to the rest of the system?**
  _626 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_controller.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.020202020202020204 - nodes in this community are weakly interconnected._
- **Why does `appControllerProvider` connect `appControllerProvider` to `app_controller.dart`, `news_screen.dart`, `../data/models/models.dart`, `package:flutter/material.dart`, `ConsumerState`, `home_screen.dart`, `shell_screen.dart`, `StatelessWidget`, `schedule_screen.dart`, `new_anime_screen.dart`?**
  _High betweenness centrality (0.025) - this node is a cross-community bridge._
- **Should `index.js` be split into smaller, more focused modules?**
  _Cohesion score 0.05792620078334364 - nodes in this community are weakly interconnected._
- **Why does `Episode` connect `episode_target.dart` to `episode.dart`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Should `anime_query.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03508771929824561 - nodes in this community are weakly interconnected._