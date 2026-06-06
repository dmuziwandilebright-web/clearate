enum Currency {
  usd(code: 'USD', uiLabel: 'USD'),
  zar(code: 'ZAR', uiLabel: 'ZAR'),
  zwg(code: 'ZWG', uiLabel: 'ZiG');

  const Currency({required this.code, required this.uiLabel});

  /// ISO-like currency code used in logic/storage.
  final String code;

  /// User-facing label. We show "ZiG" but keep "ZWG" internally.
  final String uiLabel;

  static Currency fromCode(String code) {
    return Currency.values.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
    );
  }
}

