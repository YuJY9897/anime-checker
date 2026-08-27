class BackupSummary {
  const BackupSummary({
    required this.total,
    required this.dropped,
    required this.wish,
    required this.watched,
  });

  final int total;
  final int dropped;
  final int wish;
  final int watched;
}
