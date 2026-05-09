import 'package:intl/intl.dart';

/// Formatting utilities for stock data display.
/// Design: DESIGN.md Data Display Format spec.
class Formatters {
  Formatters._();

  /// Format stock price: ¥45.20
  static String formatPrice(double? price) {
    if (price == null || price == 0) return '--';
    return '¥${price.toStringAsFixed(2)}';
  }

  /// Format large price (display-lg): ¥45.20
  static String formatPriceLarge(double? price) {
    if (price == null || price == 0) return '--';
    return '¥${price.toStringAsFixed(2)}';
  }

  /// Format change percentage: +2.35% / -1.28%
  static String formatChangePct(double? pct) {
    if (pct == null) return '--';
    final prefix = pct >= 0 ? '+' : '';
    return '$prefix${pct.toStringAsFixed(2)}%';
  }

  /// Format change amount: +1.05 / -0.82
  static String formatChangeAmt(double? amt) {
    if (amt == null) return '--';
    final prefix = amt >= 0 ? '+' : '';
    return '$prefix${amt.toStringAsFixed(2)}';
  }

  /// Format market cap: 8,542亿
  static String formatMarketCap(double? cap) {
    if (cap == null) return '--';
    if (cap >= 10000) {
      return '${(cap / 10000).toStringAsFixed(1)}万亿';
    }
    final formatter = NumberFormat('#,##0');
    return '${formatter.format(cap.round())}亿';
  }

  /// Format PE ratio: 12.8
  static String formatPE(double? pe) {
    if (pe == null) return '--';
    return pe.toStringAsFixed(1);
  }

  /// Format volume: 125,400手
  static String formatVolume(double? volume) {
    if (volume == null) return '--';
    final formatter = NumberFormat('#,##0');
    return '${formatter.format(volume.round())}手';
  }

  /// Format date: 4月10日
  static String formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  /// Format time: 14:30
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Format relative time: 3小时前 / 昨天 / 4月8日
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return formatDate(dateTime);
  }

  /// Format expected range: ¥43.5-46.8
  static String formatRange(double? low, double? high) {
    if (low == null || high == null) return '--';
    return '预期波动 ¥${low.toStringAsFixed(1)}-¥${high.toStringAsFixed(1)}';
  }
}
