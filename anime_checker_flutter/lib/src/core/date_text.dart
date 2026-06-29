import 'package:intl/intl.dart';

DateTime? parseDate(String value) {
  if (value.trim().isEmpty) return null;
  final normalized = value.trim().replaceAll('.', '-');
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

String formatNewAnimeAirDate(String value, {DateTime? now}) {
  final date = parseDate(value);
  if (date == null) return '방영일: 확인 중';
  final today = DateTime(
    now?.year ?? DateTime.now().year,
    now?.month ?? DateTime.now().month,
    now?.day ?? DateTime.now().day,
  );
  final target = DateTime(date.year, date.month, date.day);
  if (target.isAfter(today)) {
    return '방영일: ${formatDotDate(target)} 방영예정';
  }
  return '방영일: ${formatDotDate(target)}';
}

String weekdayLabel(DateTime date) {
  const labels = ['월', '화', '수', '목', '금', '토', '일'];
  return '${labels[date.weekday - 1]}요일';
}

String nowBasisText() => '${formatDotDate(DateTime.now(), withTime: true)} 기준';
