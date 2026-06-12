import 'package:intl/intl.dart';

import '../domain/currency.dart';

final _rateNumber2 = NumberFormat('#,##0.00');
final _rateNumber3 = NumberFormat('#,##0.000');
final _moneyNumber = NumberFormat('#,##0.00');
final _updatedLabel = DateFormat('h:mm a');
final _rateStampLabel = DateFormat('EEE d MMM yyyy • h:mm a');
final _rateDateLabel = DateFormat('EEEE d MMMM');

String formatRate(double value) {
  if (value.abs() < 1) {
    return _rateNumber3.format(value);
  }
  return _rateNumber2.format(value);
}

String formatMoney(double value) => _moneyNumber.format(value);

String currencySymbol(Currency currency) {
  return switch (currency) {
    Currency.usd => r'$',
    Currency.zar => 'R',
    Currency.zwg => 'ZiG',
    Currency.bwp => 'P',
  };
}

String formatCurrencyAmount(Currency currency, double value) {
  return '${currencySymbol(currency)}${formatMoney(value)}';
}

String formatHonestUpdated(DateTime time) {
  final local = time.toLocal();
  final now = DateTime.now();
  final isToday = local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  final timeLabel = _updatedLabel.format(local);
  return isToday
      ? 'Today $timeLabel'
      : '${DateFormat('MMM d').format(local)} $timeLabel';
}

String formatRateStamp(DateTime time) {
  return _rateStampLabel.format(time.toLocal());
}

String formatLocalSavedRateLabel(DateTime time) {
  final local = time.toLocal();
  final now = DateTime.now();
  final isToday = local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (isToday) {
    return 'Last saved: Today ${DateFormat('h:mm a').format(local)}';
  }
  return 'Last saved: ${DateFormat('EEE d MMM yyyy').format(local)}';
}

String formatRateDateLabel(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final parsed = DateFormat('dd-MM-yyyy').parseStrict(raw);
    return _rateDateLabel.format(parsed);
  } catch (_) {
    return raw;
  }
}
