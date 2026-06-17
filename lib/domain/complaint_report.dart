import 'package:flutter/foundation.dart';

import 'verdict.dart';

enum ComplaintTransactionType { goodsPurchase, currencyExchange }

extension ComplaintTransactionTypeX on ComplaintTransactionType {
  String get apiValue => switch (this) {
        ComplaintTransactionType.goodsPurchase => 'goods_purchase',
        ComplaintTransactionType.currencyExchange => 'currency_exchange',
      };

  String get uiLabel => switch (this) {
        ComplaintTransactionType.goodsPurchase => 'Buying something',
        ComplaintTransactionType.currencyExchange => 'Exchanging money',
      };
}

@immutable
class ComplaintReport {
  const ComplaintReport({
    required this.referenceNumber,
    required this.verdict,
    required this.status,
    required this.transactionType,
    required this.fromCurrency,
    required this.toCurrency,
    required this.priceKnown,
    required this.priceQuoted,
    required this.fairPrice,
    required this.differenceAmount,
    required this.differencePct,
    required this.thresholdUpperPct,
    required this.thresholdLowerPct,
    required this.thresholdSource,
    required this.marketVolatile,
    required this.rbzRate,
    required this.rateDate,
    required this.serverTime,
    required this.appVersion,
    required this.submittedAt,
    required this.verdictCardBase64,
    required this.town,
    this.businessName,
    this.itemName,
    this.exchangeLocationType,
    this.description,
    this.resolutionNote,
    this.witnessConsent = false,
    this.witnessPhone,
  });

  final String referenceNumber;
  final String verdict;
  final ComplaintTransactionType transactionType;
  final String fromCurrency;
  final String toCurrency;
  final double priceKnown;
  final double priceQuoted;
  final double fairPrice;
  final double differenceAmount;
  final double differencePct;
  final double thresholdUpperPct;
  final double thresholdLowerPct;
  final String thresholdSource;
  final bool marketVolatile;
  final double rbzRate;
  final String rateDate;
  final String serverTime;
  final String appVersion;
  final String status;
  final DateTime submittedAt;
  final String verdictCardBase64;
  final String town;
  final String? businessName;
  final String? itemName;
  final String? exchangeLocationType;
  final String? description;
  final String? resolutionNote;
  final bool witnessConsent;
  final String? witnessPhone;

  Map<String, Object?> toJson() => <String, Object?>{
        'reference': referenceNumber,
        'verdict': verdict,
        'transaction_type': transactionType.apiValue,
        'from_currency': fromCurrency,
        'to_currency': toCurrency,
        'price_known': priceKnown,
        'price_quoted': priceQuoted,
        'fair_price': fairPrice,
        'difference_amount': differenceAmount,
        'difference_pct': differencePct,
        'threshold_upper_pct': thresholdUpperPct,
        'threshold_lower_pct': thresholdLowerPct,
        'threshold_source': thresholdSource,
        'market_volatile': marketVolatile,
        'rbz_rate': rbzRate,
        'rate_date': rateDate,
        'server_time': serverTime,
        'app_version': appVersion,
        'status': status,
        'submitted_at': submittedAt.toIso8601String(),
        'verdict_card_base64': verdictCardBase64,
        'town': town,
        'business_name': businessName,
        'item_name': itemName,
        'exchange_location_type': exchangeLocationType,
        'description': description,
        'resolution_note': resolutionNote,
        'witness_consent': witnessConsent,
        'witness_phone': witnessPhone,
      };

  static ComplaintReport? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = json.cast<String, Object?>();
    final transactionType = switch (map['transaction_type']?.toString()) {
      'currency_exchange' => ComplaintTransactionType.currencyExchange,
      _ => ComplaintTransactionType.goodsPurchase,
    };

    final submittedAt = _readDate(map['submitted_at']);
    if (submittedAt == null) return null;

    return ComplaintReport(
      referenceNumber: map['reference']?.toString() ?? '',
      verdict: map['verdict']?.toString() ?? '',
      transactionType: transactionType,
      fromCurrency: map['from_currency']?.toString() ?? '',
      toCurrency: map['to_currency']?.toString() ?? '',
      priceKnown: _readNum(map['price_known']),
      priceQuoted: _readNum(map['price_quoted']),
      fairPrice: _readNum(map['fair_price']),
      differenceAmount: _readNum(map['difference_amount']),
      differencePct: _readNum(map['difference_pct']),
      thresholdUpperPct: _readNum(map['threshold_upper_pct']),
      thresholdLowerPct: _readNum(map['threshold_lower_pct']),
      thresholdSource: map['threshold_source']?.toString() ?? '',
      marketVolatile: map['market_volatile'] == true,
      rbzRate: _readNum(map['rbz_rate']),
      rateDate: map['rate_date']?.toString() ?? '',
      serverTime: map['server_time']?.toString() ?? '',
      appVersion: map['app_version']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      submittedAt: submittedAt,
      verdictCardBase64: map['verdict_card_base64']?.toString() ??
          map['verdict_card_url']?.toString() ??
          '',
      town: map['town']?.toString() ?? '',
      businessName: map['business_name']?.toString(),
      itemName: map['item_name']?.toString(),
      exchangeLocationType: map['exchange_location_type']?.toString(),
      description: map['description']?.toString(),
      resolutionNote: map['resolution_note']?.toString(),
      witnessConsent: map['witness_consent'] == true,
      witnessPhone: map['witness_phone']?.toString(),
    );
  }
}

double _readNum(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

DateTime? _readDate(Object? value) {
  if (value is DateTime) return value;
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
