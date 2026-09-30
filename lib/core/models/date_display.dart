/// Human-readable forms of the timestamps the API sends.
///
/// Laravel serialises datetimes as ISO-8601 in UTC
/// ("2026-09-17T15:25:34.000000Z"), which is unreadable on a card. These
/// helpers shorten it and show it in the device's local time; anything
/// they can't parse is returned unchanged rather than blanked out.
library;

String shortDateTime(String? raw) {
  final parsed = DateTime.tryParse(raw ?? '');
  if (parsed == null) return raw ?? '';
  final local = parsed.toLocal();
  return '${_date(local)} ${_time(local)}';
}

String shortDate(String? raw) {
  final parsed = DateTime.tryParse(raw ?? '');
  return parsed == null ? (raw ?? '') : _date(parsed.toLocal());
}

String _date(DateTime d) => '${d.year}-${_pad(d.month)}-${_pad(d.day)}';
String _time(DateTime d) => '${_pad(d.hour)}:${_pad(d.minute)}';
String _pad(int value) => value.toString().padLeft(2, '0');
