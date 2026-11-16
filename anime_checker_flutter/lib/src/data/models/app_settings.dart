// 편성표는 보류작을 늘 포함하고 요일도 늘 추론한다. 예전에는 이 둘을
// 설정으로 두었지만 환경설정 화면에도 없고 계산에서도 보지 않아서 뺐다.
// 예전 백업에 그 키가 남아 있어도 fromJson이 모르는 키를 무시하므로 괜찮다.
/// TMDB(JustWatch)가 한국에 주는 시청처 26곳 가운데, 애니를 보는 데
/// 실제로 쓰이는 곳만 처음부터 켜 둔다. 나머지는 환경설정에서 켤 수 있다.
/// 「Netflix Standard with Ads」는 넷플릭스 광고 요금제라 같은 곳이 두 번
/// 보이므로 빼 두었다.
const defaultWatchProviders = <String>[
  'Netflix',
  'TVING',
  'wavve',
  'Watcha',
  'Coupang Play',
  'Disney Plus',
  'Crunchyroll',
];

/// 한국에 있는 시청처 전체. 환경설정에서 고를 수 있는 목록이다.
const koreanWatchProviders = <String>[
  'Netflix',
  'Netflix Standard with Ads',
  'TVING',
  'wavve',
  'Watcha',
  'Coupang Play',
  'Disney Plus',
  'Crunchyroll',
  'Amazon Prime Video',
  'Apple TV',
  'Tencent Video',
  'Plex',
  'MUBI',
  'Curiosity Stream',
  'Magellan TV',
  'Hoichoi',
  'Sun Nxt',
  'Artify',
  'CaixaForum+',
  'Cultpix',
  'DOCSVILLE',
  'Dekkoo',
  'FOUND TV',
  'JustWatch TV Beta',
  'KableOne',
  'WOW Presents Plus',
];

class AppSettings {
  const AppSettings({
    required this.librarySort,
    required this.showPosterImages,
    required this.showNewsImages,
    required this.openNewsInsideApp,
    required this.darkMode,
    required this.watchProviders,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      librarySort: 'title',
      // 기본은 작은 표지 한 줄 목록. 한 화면에 더 많이 담기고, 큰 표지는
      // 보고 싶은 사람이 환경설정에서 켠다.
      showPosterImages: false,
      showNewsImages: true,
      openNewsInsideApp: true,
      darkMode: true,
      watchProviders: defaultWatchProviders,
    );
  }

  final String librarySort;
  final bool showPosterImages;
  final bool showNewsImages;
  final bool openNewsInsideApp;
  final bool darkMode;

  /// 상세 화면에 보여줄 시청처. 비어 있으면 아무 곳도 보여주지 않는다.
  final List<String> watchProviders;

  AppSettings copyWith({
    String? librarySort,
    bool? showPosterImages,
    bool? showNewsImages,
    bool? openNewsInsideApp,
    bool? darkMode,
    List<String>? watchProviders,
  }) => AppSettings(
    librarySort: librarySort ?? this.librarySort,
    showPosterImages: showPosterImages ?? this.showPosterImages,
    showNewsImages: showNewsImages ?? this.showNewsImages,
    openNewsInsideApp: openNewsInsideApp ?? this.openNewsInsideApp,
    darkMode: darkMode ?? this.darkMode,
    watchProviders: watchProviders ?? this.watchProviders,
  );

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    final defaults = AppSettings.defaults();
    if (json == null) return defaults;
    return defaults.copyWith(
      librarySort: json['librarySort'] as String? ?? defaults.librarySort,
      showPosterImages:
          json['showPosterImages'] as bool? ?? defaults.showPosterImages,
      showNewsImages:
          json['showNewsImages'] as bool? ?? defaults.showNewsImages,
      openNewsInsideApp:
          json['openNewsInsideApp'] as bool? ?? defaults.openNewsInsideApp,
      darkMode: json['darkMode'] as bool? ?? defaults.darkMode,
      // 이 키가 없던 저장본은 기본 7곳으로 연다. 빈 목록을 저장한 사람은
      // 일부러 다 끈 것이므로 그대로 둔다.
      watchProviders: json['watchProviders'] == null
          ? defaults.watchProviders
          : (json['watchProviders'] as List)
                .map((item) => '$item')
                .where(koreanWatchProviders.contains)
                .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'librarySort': librarySort,
    'showPosterImages': showPosterImages,
    'showNewsImages': showNewsImages,
    'openNewsInsideApp': openNewsInsideApp,
    'darkMode': darkMode,
    'watchProviders': watchProviders,
  };
}
