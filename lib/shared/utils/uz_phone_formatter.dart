import 'package:flutter/services.dart';

/// Formats input as +998 XX YYY YY YY.
/// The +998 prefix is always enforced — the user types only the 9 subscriber digits.
class UzPhoneFormatter extends TextInputFormatter {
  static const _prefix = '+998';

  /// Initial value to pre-fill a phone field so the prefix is visible immediately.
  static const initialValue = _prefix;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    String sub;

    if (text.startsWith(_prefix)) {
      // Normal case: extract subscriber digits after the prefix.
      sub = text.substring(_prefix.length).replaceAll(RegExp(r'\D'), '');
    } else {
      // User deleted part of the prefix — recover subscriber digits from all digits.
      final all = text.replaceAll(RegExp(r'\D'), '');
      sub = all.startsWith('998') ? all.substring(3) : all;
    }

    if (sub.length > 9) sub = sub.substring(0, 9);
    return _build(sub);
  }

  static TextEditingValue _build(String sub) {
    final buf = StringBuffer(_prefix);
    for (var i = 0; i < sub.length; i++) {
      // Spaces: before position 0, 2, 5, 7 → "+998 XX YYY YY YY"
      if (i == 0 || i == 2 || i == 5 || i == 7) buf.write(' ');
      buf.write(sub[i]);
    }
    final s = buf.toString();
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }

  /// Returns true when the value represents a complete UZ number (12 digits starting with 998).
  static bool isComplete(String value) {
    final d = value.replaceAll(RegExp(r'\D'), '');
    return d.length == 12 && d.startsWith('998');
  }

  /// Strips formatting and returns raw digits (e.g. "998901234567").
  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  /// Returns the number in E.164 format (+998XXXXXXXXX).
  /// If not complete, returns the input unchanged.
  static String toE164(String value) {
    final d = digitsOnly(value);
    return (d.length == 12 && d.startsWith('998')) ? '+$d' : value;
  }

  /// Converts a stored phone (E.164 or raw digits) to the display format
  /// "+998 XX YYY YY YY". Returns [initialValue] if the input is empty.
  static String toDisplay(String? raw) {
    if (raw == null || raw.isEmpty) return initialValue;
    final d = digitsOnly(raw);
    final sub = d.startsWith('998') && d.length >= 3
        ? d.substring(3)
        : d;
    final trimmed = sub.length > 9 ? sub.substring(0, 9) : sub;
    return _build(trimmed).text;
  }
}
