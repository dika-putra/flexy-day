import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'theme.dart';

(Color, Color) statusColors(AppColors c, DayStatus s) => switch (s) {
      DayStatus.office => (c.office, c.onOffice),
      DayStatus.leave => (c.leave, c.onLeave),
      DayStatus.sick => (c.sick, c.onSick),
      DayStatus.rescheduled => (c.moved, c.onMoved),
    };

(Color, Color) levelColors(AppColors c, QuotaLevel l) => switch (l) {
      QuotaLevel.green => (c.qGreen, Colors.white),
      QuotaLevel.yellow => (c.qYellow, const Color(0xFF1B1A2E)),
      QuotaLevel.red => (c.qRed, Colors.white),
    };

class NavEntry {
  const NavEntry(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class FloatingNav extends StatelessWidget {
  const FloatingNav({
    super.key,
    required this.entries,
    required this.index,
    required this.onChanged,
  });

  final List<NavEntry> entries;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.primaryContainer),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < entries.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: i == index ? cs.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      i == index ? entries[i].activeIcon : entries[i].icon,
                      size: 22,
                      color: i == index ? cs.primary : context.colors.ink2,
                    ),
                    if (i == index) ...[
                      const SizedBox(width: 6),
                      Text(
                        entries[i].label,
                        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.colors});

  final String label;
  final int value;
  final (Color, Color) colors;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: colors.$1, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: colors.$2, fontWeight: FontWeight.w600, fontSize: 12)),
            const Spacer(),
            Text('$value', style: TextStyle(color: colors.$2, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
      );
}

// Dots for small quotas, a bar for large ones (12 dots would not fit).
class QuotaProgress extends StatelessWidget {
  const QuotaProgress({super.key, required this.total, required this.done, required this.color});

  final int total;
  final int done;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final empty = context.colors.tint;
    if (total > 7) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : (done / total).clamp(0, 1).toDouble(),
          minHeight: 8,
          color: color,
          backgroundColor: empty,
        ),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(shape: BoxShape.circle, color: i < done ? color : empty),
          ),
      ],
    );
  }
}
