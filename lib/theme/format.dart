import 'package:aves/theme/text.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

String formatDay(DateTime date, String locale) => DateFormat.yMMMd(locale).format(date);

String formatTime(DateTime date, String locale, bool use24hour) => (use24hour ? DateFormat.Hm(locale) : DateFormat.jm(locale)).format(date);

String formatDateTime(DateTime date, String locale, bool use24hour) => [
      formatDay(date, locale),
      formatTime(date, locale, use24hour),
    ].join(AText.separator);

String formatFriendlyDuration(Duration d) {
  final seconds = (d.inSeconds.remainder(Duration.secondsPerMinute)).toString().padLeft(2, '0');
  if (d.inHours == 0) return '${d.inMinutes}:$seconds';

  final minutes = (d.inMinutes.remainder(Duration.minutesPerHour)).toString().padLeft(2, '0');
  return '${d.inHours}:$minutes:$seconds';
}

String formatPreciseDuration(Duration d) {
  final millis = ((d.inMicroseconds / 1000.0).round() % 1000).toString().padLeft(3, '0');
  final seconds = (d.inSeconds.remainder(Duration.secondsPerMinute)).toString().padLeft(2, '0');
  final minutes = (d.inMinutes.remainder(Duration.minutesPerHour)).toString().padLeft(2, '0');
  final hours = (d.inHours).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds.$millis';
}

String formatToLocalDuration(BuildContext context,Duration d) {
  final seconds =d.inSeconds;
  if (seconds == 0) {
    return '0 ${context.l10n.durationDialogSeconds}';
  }
  final int _hours = seconds ~/ Duration.secondsPerHour;
  final int _minutes = (seconds - _hours * Duration.secondsPerHour) ~/
      Duration.secondsPerMinute;
  final int _seconds = seconds % Duration.secondsPerMinute;
  List<String> parts = [];
  if (_hours > 0) {
    parts.add('$_hours ${context.l10n.durationDialogHours}');
  }
  if (_minutes > 0) {
    parts.add('$_minutes ${context.l10n.durationDialogMinutes}');
  }
  if (_seconds > 0) {
    parts.add('$_seconds ${context.l10n.durationDialogSeconds}');
  }
  return parts.join('\n');
}