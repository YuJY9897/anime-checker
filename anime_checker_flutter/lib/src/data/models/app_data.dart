import 'dart:convert';

import 'anime.dart';
import 'app_settings.dart';
import 'wish_item.dart';

class AppData {
  const AppData({
    required this.animeList,
    required this.watchedEpisodes,
    required this.watchedMovies,
    required this.wishList,
    required this.dropped,
    required this.animeNotes,
    required this.droppedReasons,
    required this.animeSyncedAt,
    required this.updatedAt,
    required this.backupVersion,
    required this.lastBackupAt,
    required this.settings,
  });

  factory AppData.empty() => AppData(
    animeList: const {},
    watchedEpisodes: const {},
    watchedMovies: const {},
    wishList: const {},
    dropped: const {},
    animeNotes: const {},
    droppedReasons: const {},
    animeSyncedAt: const {},
    updatedAt: DateTime.now(),
    backupVersion: 1,
    lastBackupAt: null,
    settings: AppSettings.defaults(),
  );

  final Map<String, Anime> animeList;
  final Map<String, bool> watchedEpisodes;
  final Map<String, bool> watchedMovies;
  final Map<String, WishItem> wishList;
  final Map<String, bool> dropped;
  final Map<String, String> animeNotes;
  final Map<String, String> droppedReasons;

  /// 작품별 마지막 회차 동기화 시각(ISO8601).
  final Map<String, String> animeSyncedAt;
  final DateTime updatedAt;
  final int backupVersion;
  final DateTime? lastBackupAt;
  final AppSettings settings;

  AppData copyWith({
    Map<String, Anime>? animeList,
    Map<String, bool>? watchedEpisodes,
    Map<String, bool>? watchedMovies,
    Map<String, WishItem>? wishList,
    Map<String, bool>? dropped,
    Map<String, String>? animeNotes,
    Map<String, String>? droppedReasons,
    Map<String, String>? animeSyncedAt,
    DateTime? updatedAt,
    int? backupVersion,
    DateTime? lastBackupAt,
    AppSettings? settings,
  }) => AppData(
    animeList: animeList ?? this.animeList,
    watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
    watchedMovies: watchedMovies ?? this.watchedMovies,
    wishList: wishList ?? this.wishList,
    dropped: dropped ?? this.dropped,
    animeNotes: animeNotes ?? this.animeNotes,
    droppedReasons: droppedReasons ?? this.droppedReasons,
    animeSyncedAt: animeSyncedAt ?? this.animeSyncedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    backupVersion: backupVersion ?? this.backupVersion,
    lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    settings: settings ?? this.settings,
  );

  factory AppData.fromJson(Map<String, dynamic> json) {
    Map<String, Anime> animeMapFrom(dynamic value) =>
        (value as Map? ?? const {}).map(
          (key, item) => MapEntry(
            '$key',
            Anime.fromJson(Map<String, dynamic>.from(item as Map)),
          ),
        );
    Map<String, bool> boolMapFrom(dynamic value) => (value as Map? ?? const {})
        .map((key, item) => MapEntry('$key', item == true));
    Map<String, String> stringMapFrom(dynamic value) =>
        (value as Map? ?? const {}).map(
          (key, item) => MapEntry('$key', '$item'),
        );
    Map<String, WishItem> wishMapFrom(dynamic value) =>
        (value as Map? ?? const {}).map(
          (key, item) => MapEntry(
            '$key',
            WishItem.fromJson(Map<String, dynamic>.from(item as Map)),
          ),
        );
    return AppData(
      animeList: animeMapFrom(json['animeList']),
      watchedEpisodes: boolMapFrom(json['watchedEpisodes']),
      watchedMovies: boolMapFrom(json['watchedMovies']),
      wishList: wishMapFrom(json['wishList']),
      dropped: boolMapFrom(json['dropped']),
      animeNotes: stringMapFrom(json['animeNotes']),
      droppedReasons: stringMapFrom(json['droppedReasons']),
      animeSyncedAt: stringMapFrom(json['animeSyncedAt']),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      backupVersion: (json['backupVersion'] as num?)?.toInt() ?? 1,
      lastBackupAt: DateTime.tryParse(json['lastBackupAt'] as String? ?? ''),
      settings: AppSettings.fromJson(
        json['settings'] is Map
            ? Map<String, dynamic>.from(json['settings'] as Map)
            : null,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'animeList': animeList.map((key, value) => MapEntry(key, value.toJson())),
    'watchedEpisodes': watchedEpisodes,
    'watchedMovies': watchedMovies,
    'wishList': wishList.map((key, value) => MapEntry(key, value.toJson())),
    'dropped': dropped,
    'animeNotes': animeNotes,
    'droppedReasons': droppedReasons,
    'animeSyncedAt': animeSyncedAt,
    'updatedAt': updatedAt.toIso8601String(),
    'backupVersion': backupVersion,
    'lastBackupAt': lastBackupAt?.toIso8601String(),
    'settings': settings.toJson(),
  };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
