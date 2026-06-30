enum Currency {
  iqd,
  usd;

  String toDisplayString() => name.toUpperCase();

  static Currency fromString(String value) {
    return Currency.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => Currency.iqd,
    );
  }
}
