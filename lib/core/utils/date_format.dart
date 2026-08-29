/// Formatta una data come 'yyyy-MM-dd', per le colonne Postgres `date`.
String formatDateOnly(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
}
