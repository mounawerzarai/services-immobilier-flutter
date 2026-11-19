String _two(int n) => n.toString().padLeft(2, '0');

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

int _daysAgo(DateTime d, DateTime now) =>
    _day(now).difference(_day(d)).inHours ~/ 24;

const _weekdays = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
const _months = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

/// Heure d'un message : « 14:05 ».
String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// Date courte pour la liste : « 14:05 », « Hier », « lun. », « 12/11/2026 ».
String formatConversationDate(DateTime? d, [DateTime? now]) {
  if (d == null) return '';
  final days = _daysAgo(d, now ?? DateTime.now());
  if (days <= 0) return formatTime(d);
  if (days == 1) return 'Hier';
  if (days < 7) return _weekdays[d.weekday - 1];
  return '${_two(d.day)}/${_two(d.month)}/${d.year}';
}

/// Séparateur de jour dans le chat : « Aujourd’hui », « Hier », « 12 novembre 2026 ».
String formatDayLabel(DateTime d, [DateTime? now]) {
  final days = _daysAgo(d, now ?? DateTime.now());
  if (days <= 0) return 'Aujourd’hui';
  if (days == 1) return 'Hier';
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
