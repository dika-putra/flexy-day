import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import '../domain/schedule.dart';
import '../l10n/l10n.dart';
import 'answer_panel.dart';
import 'format.dart';
import 'icons.dart';
import 'theme.dart';
import 'widgets.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime? _month;

  void _shift(int months) {
    final m = _month!;
    setState(() => _month = DateTime(m.year, m.month + months, 1));
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(ctxProvider);
    final l = context.l10n;
    final colors = context.colors;
    final primary = Theme.of(context).colorScheme.primary;
    final month = _month ??= monthStart(c.today);
    final lead = month.weekday - 1;
    final last = monthEnd(month).day;
    final weekdays = shortWeekdays(context);

    Widget cell(int day) {
      final d = DateTime(month.year, month.month, day);
      final log = c.logFor(d);
      final holiday = c.holidays.contains(d);
      final tappable = isWeekday(d) && !holiday;
      final missing = d.isBefore(c.today) &&
          log == null &&
          !d.isBefore(c.settings.trackingSince) &&
          needsAnswer(d, c.settings, c.logs, c.holidays);
      final fill = log == null ? null : statusColors(colors, log.status);
      final border = d == c.today
          ? Border.all(color: primary, width: 2)
          : missing
              ? Border.all(color: colors.qRed, width: 1.5)
              : null;
      return GestureDetector(
        onTap: tappable ? () => showAnswerSheet(context, d) : null,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fill?.$1, border: border),
          child: Text(
            '$day',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: fill?.$2 ?? (holiday ? colors.qRed : (isWeekday(d) ? colors.ink : colors.ink2)),
            ),
          ),
        ),
      );
    }

    Widget legend(Color color, String label, {bool ring = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ring ? null : color,
                border: ring ? Border.all(color: color, width: 1.5) : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, color: colors.ink2)),
          ],
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(AppIcons.prev), onPressed: () => _shift(-1)),
            Text(
              fmtMonth(context, month),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            IconButton(icon: const Icon(AppIcons.next), onPressed: () => _shift(1)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Center(child: Text(w, style: TextStyle(fontSize: 11, color: colors.ink2))),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (var i = 0; i < lead; i++) const SizedBox(),
            for (var day = 1; day <= last; day++) cell(day),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            legend(colors.onOffice, l.answerOffice),
            legend(colors.onLeave, l.answerLeave),
            legend(colors.onSick, l.answerSick),
            if (c.settings.mode == WorkMode.fixed) legend(colors.onMoved, l.answerMove),
            legend(colors.qRed, l.legendMissing, ring: true),
          ],
        ),
      ],
    );
  }
}
