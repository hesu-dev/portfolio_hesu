String formatApple12HourTime(DateTime time) {
  final twelveHour = time.hour % 12;
  final displayHour = twelveHour == 0 ? 12 : twelveHour;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$displayHour:$minute';
}
