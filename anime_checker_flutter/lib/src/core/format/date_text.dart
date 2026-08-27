import 'package:intl/intl.dart';

DateTime? parseDate(String value) {
  if (value.trim().isEmpty) return null;
  final trimmed = value.trim();
  final parsed = DateTime.tryParse(trimmed);
  if (parsed != null) return parsed;
  final normalized = trimmed.replaceFirstMapped(
    RegExp(r'^(\d{4})\.(\d{1,2})\.(\d{1,2})\.?'),
    (match) =>
        '${match[1]}-${match[2]!.padLeft(2, '0')}-${match[3]!.padLeft(2, '0')}',
  );
  return DateTime.tryParse(normalized);
}

String formatDotDate(DateTime date, {bool withTime = false}) {
  final pattern = withTime ? 'yyyy.MM.dd. HH:mm' : 'yyyy.MM.dd.';
  return DateFormat(pattern).format(date.toLocal());
}

String formatStoredDate(String value) {
  final date = parseDate(value);
  return date == null ? '-' : formatDotDate(date);
}

String formatNewAnimeAirDate(String value) {
  final date = parseDate(value);
  return date == null ? '방영일: 확인 중' : '방영일: ${formatDotDate(date)}';
}

String animeAiringStatusLabel(
  String airDate, {
  String status = '',
  DateTime? now,
}) {
  final date = parseDate(airDate);
  final today = DateTime(
    now?.year ?? DateTime.now().year,
    now?.month ?? DateTime.now().month,
    now?.day ?? DateTime.now().day,
  );
  if (date != null) {
    final target = DateTime(date.year, date.month, date.day);
    if (target.isAfter(today)) return '방영예정';
  }

  final normalized = status.trim().toLowerCase();
  if (normalized.contains('ended') ||
      normalized.contains('canceled') ||
      normalized.contains('cancelled') ||
      normalized.contains('종료') ||
      normalized.contains('완결') ||
      normalized.contains('종영') ||
      normalized.contains('취소')) {
    return '완결';
  }
  if (normalized.contains('planned') ||
      normalized.contains('upcoming') ||
      normalized.contains('예정')) {
    return '방영예정';
  }
  return '방영중';
}

List<String> animeBroadcastMetaLines(
  String airDate, {
  String status = '',
  bool isMovie = false,
  DateTime? now,
}) {
  if (isMovie) {
    final date = parseDate(airDate);
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final upcoming =
        date != null &&
        DateTime(date.year, date.month, date.day).isAfter(today);
    return [
      date == null ? '개봉일: 확인 중' : '개봉일: ${formatDotDate(date)}',
      upcoming ? '극장판 · 개봉예정' : '극장판',
    ];
  }
  return [
    formatNewAnimeAirDate(airDate),
    animeAiringStatusLabel(airDate, status: status, now: now),
  ];
}

bool isAnimeCurrentlyAiring(
  String airDate, {
  String status = '',
  DateTime? now,
}) {
  return animeAiringStatusLabel(airDate, status: status, now: now) == '방영중';
}

String weekdayLabel(DateTime date) {
  const labels = ['월', '화', '수', '목', '금', '토', '일'];
  return '${labels[date.weekday - 1]}요일';
}

String nowBasisText() => '${formatDotDate(DateTime.now(), withTime: true)} 기준';
