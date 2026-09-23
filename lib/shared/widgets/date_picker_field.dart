import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.showDay = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool enabled;

  /// Defaults: 1970 to five years ahead, for work and study dates.
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// "12 Mar 1994" instead of "Mar 1994", e.g. for a birth date.
  final bool showDay;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(1970);
    final last = lastDate ?? DateTime(now.year + 5);
    // Keep the starting date inside the allowed range (e.g. lastDate = today).
    var initial = value ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).toString();
    return InkWell(
      onTap: enabled ? () => _pick(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          enabled: enabled,
          suffixIcon: value != null && enabled
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null ? l10n.selectDate : (showDay ? DateFormat.yMMMd(localeCode) : DateFormat.yMMM(localeCode)).format(value!),
          style: enabled
              ? null
              : TextStyle(color: Theme.of(context).disabledColor),
        ),
      ),
    );
  }
}
