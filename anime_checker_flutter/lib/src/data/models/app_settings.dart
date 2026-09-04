class AppSettings {
  const AppSettings({
    required this.librarySort,
    required this.showPosterImages,
    required this.includeDroppedInSchedule,
    required this.inferScheduleWeekday,
    required this.showNewsImages,
    required this.openNewsInsideApp,
    required this.darkMode,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      librarySort: 'title',
      showPosterImages: true,
      includeDroppedInSchedule: true,
      inferScheduleWeekday: true,
      showNewsImages: true,
      openNewsInsideApp: true,
      darkMode: false,
    );
  }

  final String librarySort;
  final bool showPosterImages;
  final bool includeDroppedInSchedule;
  final bool inferScheduleWeekday;
  final bool showNewsImages;
  final bool openNewsInsideApp;
  final bool darkMode;

  AppSettings copyWith({
    String? librarySort,
    bool? showPosterImages,
    bool? includeDroppedInSchedule,
    bool? inferScheduleWeekday,
    bool? showNewsImages,
    bool? openNewsInsideApp,
    bool? darkMode,
  }) => AppSettings(
    librarySort: librarySort ?? this.librarySort,
    showPosterImages: showPosterImages ?? this.showPosterImages,
    includeDroppedInSchedule:
        includeDroppedInSchedule ?? this.includeDroppedInSchedule,
    inferScheduleWeekday: inferScheduleWeekday ?? this.inferScheduleWeekday,
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
      includeDroppedInSchedule:
          json['includeDroppedInSchedule'] as bool? ??
          defaults.includeDroppedInSchedule,
      inferScheduleWeekday:
          json['inferScheduleWeekday'] as bool? ??
          defaults.inferScheduleWeekday,
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
    'includeDroppedInSchedule': includeDroppedInSchedule,
    'inferScheduleWeekday': inferScheduleWeekday,
    'showNewsImages': showNewsImages,
    'openNewsInsideApp': openNewsInsideApp,
    'darkMode': darkMode,
  };
}
