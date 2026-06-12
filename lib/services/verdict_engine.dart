import '../domain/rate_snapshot.dart';
import '../domain/verdict.dart';

class VerdictEngine {
  const VerdictEngine();

  static const double _fallbackUpperPct = 10.28;
  static const double _fallbackLowerPct = 2.57;

  VerdictResult evaluate({
    required double itemPrice,
    required double askedToPay,
    required double officialRate,
    RateThresholds? thresholds,
  }) {
    if (itemPrice <= 0) {
      throw ArgumentError.value(itemPrice, 'itemPrice', 'Must be > 0');
    }
    if (askedToPay < 0) {
      throw ArgumentError.value(askedToPay, 'askedToPay', 'Must be >= 0');
    }

    final shopRate = askedToPay / itemPrice;
    final upperPct = thresholds?.upperPct ?? _fallbackUpperPct;
    final lowerPct = thresholds?.lowerPct ?? _fallbackLowerPct;
    final overEdge = officialRate * (1 + (upperPct / 100));
    final underEdge = officialRate * (1 - (lowerPct / 100));
    final fairPay = itemPrice * officialRate;
    final isVolatile = thresholds?.isVolatile ?? false;
    final thresholdSource = thresholds?.source ?? 'reference_rate';

    if (shopRate > overEdge) {
      return VerdictResult(
        kind: VerdictKind.overcharged,
        officialRate: officialRate,
        shopRate: shopRate,
        expectedPay: fairPay,
        deltaAmount: askedToPay - fairPay,
        itemPrice: itemPrice,
        askedToPay: askedToPay,
        upperThresholdPct: upperPct,
        lowerThresholdPct: lowerPct,
        isVolatile: isVolatile,
        thresholdSource: thresholdSource,
      );
    }

    if (shopRate < underEdge) {
      return VerdictResult(
        kind: VerdictKind.undervalued,
        officialRate: officialRate,
        shopRate: shopRate,
        expectedPay: fairPay,
        deltaAmount: fairPay - askedToPay,
        itemPrice: itemPrice,
        askedToPay: askedToPay,
        upperThresholdPct: upperPct,
        lowerThresholdPct: lowerPct,
        isVolatile: isVolatile,
        thresholdSource: thresholdSource,
      );
    }

    return VerdictResult(
      kind: VerdictKind.fair,
      officialRate: officialRate,
      shopRate: shopRate,
      expectedPay: fairPay,
      deltaAmount: (askedToPay - fairPay).abs(),
      itemPrice: itemPrice,
      askedToPay: askedToPay,
      upperThresholdPct: upperPct,
      lowerThresholdPct: lowerPct,
      isVolatile: isVolatile,
      thresholdSource: thresholdSource,
    );
  }
}
