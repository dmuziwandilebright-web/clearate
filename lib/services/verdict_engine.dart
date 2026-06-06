import '../config/app_config.dart';
import '../domain/verdict.dart';

class VerdictEngine {
  const VerdictEngine(this._config);

  final AppConfig _config;

  VerdictResult evaluate({
    required double itemPrice,
    required double askedToPay,
    required double officialRate,
  }) {
    if (itemPrice <= 0) {
      throw ArgumentError.value(itemPrice, 'itemPrice', 'Must be > 0');
    }
    if (askedToPay < 0) {
      throw ArgumentError.value(askedToPay, 'askedToPay', 'Must be >= 0');
    }

    final shopRate = askedToPay / itemPrice;
    final overEdge = officialRate * (1 + _config.overchargeThreshold);
    final underEdge = officialRate * (1 - _config.undervaluedThreshold);

    if (shopRate > overEdge) {
      final expectedPay = itemPrice * overEdge;
      return VerdictResult(
        kind: VerdictKind.overcharged,
        officialRate: officialRate,
        shopRate: shopRate,
        expectedPay: expectedPay,
        deltaAmount: askedToPay - expectedPay,
      );
    }

    if (shopRate < underEdge) {
      final expectedPay = itemPrice * underEdge;
      return VerdictResult(
        kind: VerdictKind.undervalued,
        officialRate: officialRate,
        shopRate: shopRate,
        expectedPay: expectedPay,
        deltaAmount: expectedPay - askedToPay,
      );
    }

    final expectedPay = itemPrice * officialRate;
    return VerdictResult(
      kind: VerdictKind.fair,
      officialRate: officialRate,
      shopRate: shopRate,
      expectedPay: expectedPay,
      deltaAmount: (askedToPay - expectedPay).abs(),
    );
  }
}

