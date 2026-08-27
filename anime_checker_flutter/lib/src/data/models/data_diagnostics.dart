class DataDiagnostics {
  const DataDiagnostics({
    required this.total,
    required this.noPoster,
    required this.noSeason,
    required this.noGenre,
    required this.dropped,
    required this.notes,
  });

  final int total;
  final int noPoster;
  final int noSeason;
  final int noGenre;
  final int dropped;
  final int notes;
}
