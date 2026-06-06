enum VerdictKind { fair, overcharged, undervalued }

class VerdictResult {
  const VerdictResult({
    required this.kind,
    required this.officialRate,
    required this.shopRate,
    required this.expectedPay,
    required this.deltaAmount,
  });

  final VerdictKind kind;

  /// Official mid-rate for the selected pair.
  final double officialRate;

  /// The implicit rate the shop is using: askedPay / itemPrice.
  final double shopRate;

  /// Expected asked-to-pay amount at the threshold edge used for classification.
  final double expectedPay;

  /// Positive amount above/below expectedPay (absolute currency amount).
  final double deltaAmount;
}

