import 'package:flutter/material.dart';
import '../core/shamsi_date.dart';
import '../core/persian_number.dart';
import '../core/theme.dart';

// Swiss Minimalist Financial Terminal - Interactive Shamsi Date Picker
// Invariant: ZERO half-space characters (\\u200c) allowed.
// Culture: fa-IR, Iranian Jalali calendar & Tehran timezone.

class ShamsiDatePickerModal extends StatefulWidget {
  final ShamsiDate initialDate;
  final ValueChanged<ShamsiDate> onDateSelected;

  const ShamsiDatePickerModal({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  static Future<ShamsiDate?> show(
    BuildContext context, {
    required ShamsiDate initialDate,
  }) async {
    return showModalBottomSheet<ShamsiDate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShamsiDatePickerModal(
        initialDate: initialDate,
        onDateSelected: (date) => Navigator.of(ctx).pop(date),
      ),
    );
  }

  @override
  State<ShamsiDatePickerModal> createState() => _ShamsiDatePickerModalState();
}

class _ShamsiDatePickerModalState extends State<ShamsiDatePickerModal> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;
  }

  void _goToToday() {
    final today = ShamsiDate.now();
    setState(() {
      _selectedYear = today.year;
      _selectedMonth = today.month;
      _selectedDay = today.day;
    });
  }

  void _previousMonth() {
    setState(() {
      if (_selectedMonth > 1) {
        _selectedMonth--;
      } else {
        _selectedMonth = 12;
        _selectedYear--;
      }
      final maxDays = ShamsiDate.daysInMonth(_selectedYear, _selectedMonth);
      if (_selectedDay > maxDays) _selectedDay = maxDays;
    });
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth < 12) {
        _selectedMonth++;
      } else {
        _selectedMonth = 1;
        _selectedYear++;
      }
      final maxDays = ShamsiDate.daysInMonth(_selectedYear, _selectedMonth);
      if (_selectedDay > maxDays) _selectedDay = maxDays;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = ShamsiDate.daysInMonth(_selectedYear, _selectedMonth);
    // Determine weekday of 1st day of this Shamsi month
    final firstDayShamsi = ShamsiDate(year: _selectedYear, month: _selectedMonth, day: 1);
    final firstDayDt = firstDayShamsi.toDateTime();
    // 0 is Saturday, 6 is Friday
    final startWeekdayOffset = (firstDayDt.weekday + 1) % 7;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: TerminalTheme.slateDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(
            top: BorderSide(color: TerminalTheme.goldAccent, width: 2),
            left: BorderSide(color: TerminalTheme.borderColor, width: 1),
            right: BorderSide(color: TerminalTheme.borderColor, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_month, color: TerminalTheme.goldAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'انتخاب تاریخ شمسی',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: TerminalTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _goToToday,
                  icon: const Icon(Icons.today, size: 16, color: TerminalTheme.goldAccent),
                  label: const Text(
                    'امروز',
                    style: TextStyle(color: TerminalTheme.goldAccent, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: TerminalTheme.cardDark,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Year and Month Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: TerminalTheme.cardDark,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: TerminalTheme.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _nextMonth, // In RTL, left arrow goes forward/next
                    icon: const Icon(Icons.chevron_right, color: TerminalTheme.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Row(
                    children: [
                      // Month Dropdown
                      DropdownButton<int>(
                        value: _selectedMonth,
                        dropdownColor: TerminalTheme.cardLight,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: TerminalTheme.goldAccent),
                        items: List.generate(12, (index) {
                          final m = index + 1;
                          return DropdownMenuItem(
                            value: m,
                            child: Text(
                              ShamsiDate.monthNames[index],
                              style: const TextStyle(
                                color: TerminalTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                        onChanged: (newMonth) {
                          if (newMonth != null) {
                            setState(() {
                              _selectedMonth = newMonth;
                              final maxDays = ShamsiDate.daysInMonth(_selectedYear, _selectedMonth);
                              if (_selectedDay > maxDays) _selectedDay = maxDays;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      // Year Dropdown
                      DropdownButton<int>(
                        value: _selectedYear,
                        dropdownColor: TerminalTheme.cardLight,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: TerminalTheme.goldAccent),
                        items: List.generate(21, (index) {
                          final y = 1395 + index;
                          return DropdownMenuItem(
                            value: y,
                            child: Text(
                              PersianNumber.toPersianDigits(y.toString()),
                              style: const TextStyle(
                                color: TerminalTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                        onChanged: (newYear) {
                          if (newYear != null) {
                            setState(() {
                              _selectedYear = newYear;
                              final maxDays = ShamsiDate.daysInMonth(_selectedYear, _selectedMonth);
                              if (_selectedDay > maxDays) _selectedDay = maxDays;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(Icons.chevron_left, color: TerminalTheme.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Weekday Headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ShamsiDate.weekdayNames.map((name) {
                final isFriday = name == 'جمعه';
                final shortName = name.length > 4 ? name.substring(0, 3) : name;
                return Expanded(
                  child: Center(
                    child: Text(
                      shortName,
                      style: TextStyle(
                        fontSize: 11,
                        color: isFriday ? TerminalTheme.signalCoral : TerminalTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: startWeekdayOffset + totalDays,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                if (index < startWeekdayOffset) {
                  return const SizedBox();
                }
                final dayNumber = index - startWeekdayOffset + 1;
                final isSelected = dayNumber == _selectedDay;
                final isFriday = (index % 7) == 6;

                return InkWell(
                  onTap: () {
                    setState(() => _selectedDay = dayNumber);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? TerminalTheme.goldAccent : TerminalTheme.cardDark,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? TerminalTheme.goldBright
                            : TerminalTheme.borderColor,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      PersianNumber.toPersianDigits(dayNumber.toString()),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? TerminalTheme.carbonBlack
                            : (isFriday ? TerminalTheme.signalCoral : TerminalTheme.textPrimary),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Selected Date Summary Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: TerminalTheme.cardLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: TerminalTheme.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'تاریخ انتخاب شده:',
                    style: TextStyle(fontSize: 12, color: TerminalTheme.textSecondary),
                  ),
                  Text(
                    ShamsiDate(
                      year: _selectedYear,
                      month: _selectedMonth,
                      day: _selectedDay,
                    ).format(includeTime: false),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: TerminalTheme.goldAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Confirm & Cancel Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final selected = ShamsiDate(
                        year: _selectedYear,
                        month: _selectedMonth,
                        day: _selectedDay,
                      );
                      widget.onDateSelected(selected);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TerminalTheme.goldAccent,
                      foregroundColor: TerminalTheme.carbonBlack,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'تایید تاریخ',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TerminalTheme.textSecondary,
                      side: const BorderSide(color: TerminalTheme.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('انصراف', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
