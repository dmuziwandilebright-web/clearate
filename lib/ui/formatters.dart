import 'package:intl/intl.dart';

final _rateNumber = NumberFormat('#,##0.00');
final _moneyNumber = NumberFormat('#,##0.00');
final _updatedLabel = DateFormat('EEEE HH:mm');

String formatRate(double value) => _rateNumber.format(value);

String formatMoney(double value) => _moneyNumber.format(value);

String formatHonestUpdated(DateTime time) => _updatedLabel.format(time.toLocal());

