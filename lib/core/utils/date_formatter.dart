import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatShortDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'es').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a', 'es').format(date);
  }

  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return mins <= 1 ? 'Hace un momento' : 'Hace $mins min';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? 'Hace 1 hora' : 'Hace $hours horas';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1 ? 'Ayer' : 'Hace $days días';
    } else {
      return formatShortDate(date);
    }
  }

  static String formatPromoEndDate(DateTime? endDate) {
    if (endDate == null) return 'Sin fecha límite anunciada';
    final now = DateTime.now();
    final remaining = endDate.difference(now);

    if (remaining.isNegative) {
      return 'Promoción finalizada';
    }

    if (remaining.inHours < 24) {
      final h = remaining.inHours;
      return h <= 1 ? 'Termina en menos de 1 hora' : 'Termina en $h horas';
    } else if (remaining.inDays <= 3) {
      final d = remaining.inDays;
      return 'Termina en $d ${d == 1 ? 'día' : 'días'}';
    } else {
      return 'Termina el ${DateFormat('d MMMM', 'es').format(endDate)}';
    }
  }
}
