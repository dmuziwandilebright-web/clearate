enum VerdictKind { fair, overcharged, undervalued }

class VerdictResult {
  const VerdictResult({
    required this.kind,
    required this.officialRate,
    required this.shopRate,
    required this.expectedPay,
    required this.deltaAmount,
    required this.itemPrice,
    required this.askedToPay,
    required this.upperThresholdPct,
    required this.lowerThresholdPct,
    required this.isVolatile,
    required this.thresholdSource,
  });

  final VerdictKind kind;

  /// Official mid-rate for the selected pair.
  final double officialRate;

  /// The implicit rate the shop is using: askedPay / itemPrice.
  final double shopRate;

  /// Expected fair amount at the official mid-rate.
  final double expectedPay;

  /// Positive amount above/below the fair amount (absolute currency amount).
  final double deltaAmount;

  /// User-entered original amount.
  final double itemPrice;

  /// User-entered amount being asked to pay.
  final double askedToPay;

  /// Dynamic upper threshold percent from the backend, or a safe fallback.
  final double upperThresholdPct;

  /// Dynamic lower threshold percent from the backend, or a safe fallback.
  final double lowerThresholdPct;

  /// Whether the backend marked the market as volatile.
  final bool isVolatile;

  /// Source label for the threshold logic.
  final String thresholdSource;

  double get fairLowerAmount => expectedPay * (1 - (lowerThresholdPct / 100));

  double get fairUpperAmount => expectedPay * (1 + (upperThresholdPct / 100));

  String get retailMarginSummary =>
      'Retail margin in use: +${upperThresholdPct.toStringAsFixed(2)}% / -${lowerThresholdPct.toStringAsFixed(2)}%';
}
