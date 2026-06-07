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
}
