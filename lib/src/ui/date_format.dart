String formatDateTimeYmdHm(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min';
}

String formatDateTimeStringYmdHm(String? raw) {
  final v = (raw ?? '').trim();
  if (v.isEmpty) return '';
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return v;
  final parsed = DateTime.tryParse(v);
  if (parsed == null) return v;
  return formatDateTimeYmdHm(parsed.toLocal());
}
