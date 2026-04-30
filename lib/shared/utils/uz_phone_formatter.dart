import 'package:flutter/services.dart';

/// Formats input as +998 XX YYY YY YY
/// Accepts digits only; strips and rebuilds the mask on every keystroke.
class UzPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Keep at most 12 digits (998 + 9 subscriber digits)
    final capped = digits.length > 12 ? digits.substring(0, 12) : digits;

    final buf = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 0) buf.write('+');
      if (i == 3) buf.write(' ');
      if (i == 5) buf.write(' ');
      if (i == 8) buf.write(' ');
      if (i == 10) buf.write(' ');
      buf.write(capped[i]);
    }

    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Returns true when the formatted value represents a complete UZ number.
  static bool isComplete(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length == 12 && digits.startsWith('998');
  }

  /// Strips formatting and returns raw digits (e.g. "998901234567").
  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');
}
