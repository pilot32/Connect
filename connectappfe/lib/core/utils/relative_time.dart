/// Formats a timestamp the way a feed reads it: "just now", "4h", "2d".
///
/// Deliberately not using `intl` — one small function beats another dependency
/// and a locale-loading step for what is currently a single use.
String relativeTime(DateTime? time, {DateTime? now}) {
  if (time == null) return '';
  final reference = now ?? DateTime.now();
  final diff = reference.difference(time.toLocal());

  if (diff.isNegative) return 'just now';
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  if (diff.inDays < 365) return '${(diff.inDays / 7).floor()}w';
  return '${(diff.inDays / 365).floor()}y';
}
