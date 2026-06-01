import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaseCalendar extends StatelessWidget {
  final DateTime startDate;
  final DateTime displayMonth;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onClose;
  final bool? nextMonth;

  const LeaseCalendar({
    super.key,
    required this.startDate,
    required this.displayMonth,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onClose,
    this.nextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDayOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);
    final lastDayOfMonth = DateTime(displayMonth.year, displayMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final int offsetPrev = (firstDayOfMonth.weekday - 1);

    final List<DateTime> allDays = [];
    final prevMonthLastDay = DateTime(displayMonth.year, displayMonth.month, 0);
    for (int i = offsetPrev - 1; i >= 0; i--) {
      allDays.add(prevMonthLastDay.subtract(Duration(days: i)));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      allDays.add(DateTime(displayMonth.year, displayMonth.month, d));
    }
    final int totalCells = allDays.length;
    final int weeks = (totalCells / 7).ceil();
    final int neededCells = weeks * 7;
    final int remaining = neededCells - totalCells;
    for (int i = 1; i <= remaining; i++) {
      allDays.add(DateTime(displayMonth.year, displayMonth.month + 1, i));
    }

    final cleanStart = DateTime(startDate.year, startDate.month, startDate.day);
    final cleanToday = DateTime(today.year, today.month, today.day);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! > 0) {
              if (canGoPrevious) onPreviousMonth();
            } else if (details.primaryVelocity! < 0) {
              if (canGoNext) onNextMonth();
            }
          },
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: Column(
                key: ValueKey(displayMonth),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onClose,
                        child: Icon(Icons.close, size: 20, color: theme.colorScheme.onSurface),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('LLLL yyyy', 'ru').format(displayMonth),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 20),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'].map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 1),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisExtent: 30,
                    ),
                    itemCount: allDays.length,
                    itemBuilder: (context, index) {
                      final date = allDays[index];
                      final bool isCurrentMonth = date.month == displayMonth.month;
                      final bool isInRange =
                          !date.isBefore(cleanStart) && !date.isAfter(cleanToday);

                      final bool isGlobalStart = isInRange && date == cleanStart;
                      final bool isGlobalEnd = isInRange && date == cleanToday;
                      final bool isSingleGlobal = isGlobalStart && isGlobalEnd;

                      BorderRadiusGeometry? borderRadius;
                      if (isSingleGlobal) {
                        borderRadius = BorderRadius.circular(15);
                      } else if (isGlobalStart) {
                        borderRadius = const BorderRadius.horizontal(left: Radius.circular(15));
                      } else if (isGlobalEnd) {
                        borderRadius = const BorderRadius.horizontal(right: Radius.circular(15));
                      }

                      return Container(
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isInRange
                              ? theme.primaryColor.withOpacity(0.25)
                              : Colors.transparent,
                          borderRadius: borderRadius,
                        ),
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isInRange ? FontWeight.w600 : FontWeight.normal,
                            color: isCurrentMonth
                                ? (isInRange
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withOpacity(0.8))
                                : (isInRange
                                ? theme.colorScheme.onSurface.withOpacity(0.6)
                                : theme.colorScheme.onSurface.withOpacity(0.3)),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}