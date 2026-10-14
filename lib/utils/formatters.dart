/// Davomiylikni `m:ss` yoki `h:mm:ss` ko'rinishida chiqaradi.
String formatDuration(Duration duration) {
  if (duration.inMilliseconds <= 0) return '0:00';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$ss';
  }
  return '$minutes:$ss';
}

/// "12 qo'shiq" kabi matn.
String songCountLabel(int count) => '$count qoʻshiq';
