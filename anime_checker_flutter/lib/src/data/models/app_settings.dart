// 편성표는 보류작을 늘 포함하고 요일도 늘 추론한다. 예전에는 이 둘을
// 설정으로 두었지만 환경설정 화면에도 없고 계산에서도 보지 않아서 뺐다.
// 예전 백업에 그 키가 남아 있어도 fromJson이 모르는 키를 무시하므로 괜찮다.
class AppSettings {
  const AppSettings({
    required this.librarySort,
    required this.showPosterImages,
    required this.showNewsImages,
    required this.openNewsInsideApp,
    required this.darkMode,
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
    );
  }

  final String librarySort;
  final bool showPosterImages;
  final bool showNewsImages;
  final bool openNewsInsideApp;
  final bool darkMode;

  AppSettings copyWith({
    String? librarySort,
    bool? showPosterImages,
    bool? showNewsImages,
    bool? openNewsInsideApp,
    bool? darkMode,
  }) => AppSettings(
    librarySort: librarySort ?? this.librarySort,
    showPosterImages: showPosterImages ?? this.showPosterImages,
    showNewsImages: showNewsImages ?? this.showNewsImages,
    openNewsInsideApp: openNewsInsideApp ?? this.openNewsInsideApp,
    darkMode: darkMode ?? this.darkMode,
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
    );
  }

  Map<String, dynamic> toJson() => {
    'librarySort': librarySort,
    'showPosterImages': showPosterImages,
    'showNewsImages': showNewsImages,
    'openNewsInsideApp': openNewsInsideApp,
    'darkMode': darkMode,
  };
}
