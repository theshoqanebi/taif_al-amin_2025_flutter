class PriceUtils {
  static String addCommas(dynamic value) {
    if (value == null) return '';

    String raw = value.toString().trim();
    if (raw.isEmpty) return '';

    // keep an optional leading minus sign
    bool negative = raw.startsWith('-');
    if (negative) raw = raw.substring(1);

    // split integer and decimal parts
    final parts = raw.split('.');
    String intPart = parts[0].replaceAll(',', '');
    final String? decPart = parts.length > 1 ? parts[1] : null;

    // insert commas every 3 digits from the right
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i != 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }

    String result = buffer.toString();
    if (decPart != null) result = '$result.$decPart';
    if (negative) result = '-$result';

    return result;
  }

  /// Method 2: remove commas
  /// "1,234,567"    -> "1234567"
  /// "1,234,567.89" -> "1234567.89"
  static String removeCommas(dynamic value) {
    if (value == null) return '';
    return value.toString().replaceAll(',', '').trim();
  }
}
