class AddressFormatter {

  /// Miasto + Ulica (bez numeru)
  static String short(String address) {
    if (address.isEmpty) return '';

    final parts = address.split(',');

    if (parts.length < 2) return address;

    final city = parts[0].trim();
    String street = parts[1].trim();

    /// usuń numer domu/bloku
    street = street.replaceAll(RegExp(r'\d+[A-Za-z\/\-]*'), '').trim();

    return '$city, $street';
  }

  /// pełny adres (Upcoming)
  static String full(String address) {
    return address;
  }
}