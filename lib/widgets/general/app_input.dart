import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taif_alamin/theme/app_text_style.dart';

/// Formats numbers as prices (e.g. 1,234.56)
class PriceTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(',', '');
    if (text.isEmpty) return newValue;

    final parts = text.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';
    final formatted = _addCommas(intPart) + decPart;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _addCommas(String value) {
    if (value.isEmpty) return value;
    final result = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i != 0 && (value.length - i) % 3 == 0) result.write(',');
      result.write(value[i]);
    }
    return result.toString();
  }

  static void setFormattedValue(
    TextEditingController controller,
    String rawValue,
  ) {
    final instance = PriceTextInputFormatter();
    final formatted = instance.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: rawValue),
    );
    controller.value = formatted;
  }
}

/// Formats input as DD/MM/YYYY and validates the date
class DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');

    // Allow only up to 8 digits
    if (digits.length > 8) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Returns null if valid, or an error message string if invalid
  static String? validate(String value) {
    if (value.isEmpty) return null;

    final parts = value.split('/');
    if (parts.length != 3 || value.length != 10) {
      return 'Enter a valid date (DD/MM/YYYY)';
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return 'Enter a valid date (DD/MM/YYYY)';
    }
    if (month < 1 || month > 12) return 'Month must be between 01 and 12';
    if (day < 1 || day > _daysInMonth(month, year)) {
      return 'Invalid day for the given month';
    }
    if (year < 1900 || year > 2100) return 'Year must be between 1900 and 2100';

    return null;
  }

  static int _daysInMonth(int month, int year) {
    const days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && _isLeapYear(year)) return 29;
    return days[month];
  }

  static bool _isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);

  static void setFormattedValue(
    TextEditingController controller,
    String rawValue,
  ) {
    final instance = DateTextInputFormatter();
    final formatted = instance.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: rawValue),
    );
    controller.value = formatted;
  }

  /// Parse DD/MM/YYYY format to DateTime
  static DateTime? parseDate(String value) {
    if (value.isEmpty || value.length != 10) return null;

    final parts = value.split('/');
    try {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  /// Format DateTime to DD/MM/YYYY
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class AppInput extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final TextInputType inputType;
  final TextDirection direction;
  final bool isDatePicker;
  final bool isPrice;
  final bool isDate;

  /// Locks the field for editing (value still visible, no keyboard/typing).
  /// Use for auto-generated values like bill numbers.
  final bool readOnly;
  final Function(String?)? onChanged;
  final VoidCallback? onTap;
  final Widget? suffixIcon, prefixIcon;

  const AppInput({
    super.key,
    required this.title,
    required this.controller,
    this.inputType = TextInputType.text,
    this.direction = TextDirection.rtl,
    this.isDatePicker = false,
    this.isPrice = false,
    this.isDate = false,
    this.readOnly = false,
    this.onChanged,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  String? _dateError;

  void _handleDateChanged(String value) {
    setState(() {
      // Only validate when full date is entered
      _dateError = value.length == 10
          ? DateTextInputFormatter.validate(value)
          : null;
    });
    widget.onChanged?.call(value);
  }

  /// Show date picker and update controller
  Future<void> _selectDate() async {
    // Parse current date from controller or use today
    DateTime initialDate = DateTime.now();
    if (widget.controller.text.isNotEmpty) {
      final parsed = DateTextInputFormatter.parseDate(widget.controller.text);
      if (parsed != null) {
        initialDate = parsed;
      }
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final formatted = DateTextInputFormatter.formatDate(pickedDate);
      widget.controller.text = formatted;

      // Validate the selected date
      setState(() {
        _dateError = DateTextInputFormatter.validate(formatted);
      });

      // Notify parent of the new value.
      widget.onChanged?.call(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<TextInputFormatter> numbersOnly = [
      FilteringTextInputFormatter.digitsOnly,
    ];
    final List<TextInputFormatter> decimal = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
    ];
    final List<TextInputFormatter> price = [
      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      PriceTextInputFormatter(),
    ];
    final List<TextInputFormatter> date = [
      FilteringTextInputFormatter.digitsOnly,
      DateTextInputFormatter(),
    ];

    List<TextInputFormatter>? formatters;
    TextInputType keyboardType = widget.inputType;

    if (widget.isDate) {
      formatters = date;
      keyboardType = TextInputType.number;
    } else if (widget.isPrice) {
      formatters = price;
      keyboardType = const TextInputType.numberWithOptions(decimal: true);
    } else if (widget.inputType == TextInputType.number) {
      formatters = numbersOnly;
    } else if (widget.inputType ==
        const TextInputType.numberWithOptions(decimal: true)) {
      formatters = decimal;
    }

    final bool hasError = widget.isDate && _dateError != null;
    final bool hasText = widget.controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title ABOVE the field (instead of a floating label inside).
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        TextField(
          readOnly:
              widget.readOnly ||
              widget.isDatePicker, // Make read-only if using date picker
          keyboardType: keyboardType,
          inputFormatters: formatters,
          controller: widget.controller,
          style: AppTextStyle.inputTextStyle,
          textDirection: widget.direction,
          // If the parent supplies its own date picker (onTap), use it.
          // Otherwise fall back to AppInput's built-in picker. This avoids
          // opening two pickers (parent + internal) on a single tap.
          onTap: widget.readOnly
              ? null
              : widget.isDatePicker
              ? (widget.onTap ?? _selectDate)
              : widget.onTap,
          onChanged: widget.readOnly
              ? null
              : widget.isDate
              ? _handleDateChanged
              : widget.onChanged,
          decoration: InputDecoration(
            // No labelText now — the title is rendered above the field.
            hintText: widget.isDate ? 'DD/MM/YYYY' : null,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            errorText: _dateError,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isDate
                ? widget.suffixIcon ??
                      const Icon(Icons.calendar_today, size: 18)
                : widget.suffixIcon,
            counter: null,
            filled: true,
            fillColor: (widget.readOnly && !widget.isDatePicker)
                ? const Color(0xFFF0F2F5)
                : Colors.white,
            enabledBorder: hasError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  )
                : hasText
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF003763),
                      width: 1,
                    ),
                  )
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
            focusedBorder: hasError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  )
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF003763),
                      width: 2,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
