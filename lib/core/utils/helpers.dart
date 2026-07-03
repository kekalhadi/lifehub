import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static String format(double amount, {String symbol = 'Rp'}) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: symbol,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }
}

class DateHelper {
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) return 'Hari ini';
    if (dateDay == today.subtract(const Duration(days: 1))) return 'Kemarin';
    if (dateDay == today.add(const Duration(days: 1))) return 'Besok';

    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd MMM', 'id_ID').format(date);
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isOverdue(DateTime date) {
    return date.isBefore(DateTime.now()) && !isToday(date);
  }

  static String relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return formatDate(date);
  }
}

class ColorHelper {
  static Color fromHex(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return Colors.grey;
  }

  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  static Color withOpacity(String hexColor, double opacity) {
    return fromHex(hexColor).withOpacity(opacity);
  }
}

String moodEmoji(String? mood) {
  switch (mood) {
    case 'happy': return '😊';
    case 'excited': return '🤩';
    case 'neutral': return '😐';
    case 'sad': return '😔';
    case 'stressed': return '😤';
    default: return '😊';
  }
}

String moodLabel(String? mood) {
  switch (mood) {
    case 'happy': return 'Bahagia';
    case 'excited': return 'Semangat';
    case 'neutral': return 'Biasa';
    case 'sad': return 'Sedih';
    case 'stressed': return 'Stres';
    default: return 'Bahagia';
  }
}

const List<Map<String, String>> kMoods = [
  {'key': 'excited', 'emoji': '🤩', 'label': 'Semangat'},
  {'key': 'happy', 'emoji': '😊', 'label': 'Bahagia'},
  {'key': 'neutral', 'emoji': '😐', 'label': 'Biasa'},
  {'key': 'sad', 'emoji': '😔', 'label': 'Sedih'},
  {'key': 'stressed', 'emoji': '😤', 'label': 'Stres'},
];