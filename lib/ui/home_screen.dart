import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import '../domain/quota.dart';
import '../domain/schedule.dart';
import '../domain/summary.dart';
import '../l10n/l10n.dart';
import 'answer_panel.dart';
import 'format.dart';
import 'icons.dart';
import 'theme.dart';
import 'widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(ctxProvider);
    final l = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final log = c.logFor(c.today);
    final needs = needsAnswer(c.today, c.settings, c.logs, c.holidays);
    final missing = unansweredDates(
      today: c.today,
      settings: c.settings,
      logs: c.logs,
      holidays: c.holidays,
    ).length;
    final summary = summarizeMonth(c.today, c.logs, c.holidays);
    final percent = summary.percent;
    final quota = c.settings.mode == WorkMode.quota
        ? computeQuotaStatus(
            today: c.today,
            settings: c.settings,
            logs: c.logs,
            holidays: c.holidays,
          )
        : null;

    Widget card({required Widget child, Color? color}) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color ?? colors.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        );

    Widget hero() {
      if (log == null && !needs) {
        return card(child: Text(l.notOfficeDay, style: TextStyle(color: colors.ink2)));
      }
      if (log == null) {
        return card(
          color: theme.colorScheme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.question,
                style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              AnswerPanel(date: c.today, onHero: true),
            ],
          ),
        );
      }
      final (bg, fg) = statusColors(colors, log.status);
      return card(
        color: bg,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              child: Icon(AppIcons.check, size: 20, color: bg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText(context, log),
                    style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  if (log.note != null) Text(log.note!, style: TextStyle(color: fg, fontSize: 12)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => showAnswerSheet(context, c.today),
              child: Text(l.changeAnswer, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    Widget middle() {
      if (quota != null) {
        final (bg, fg) = levelColors(colors, quota.level);
        final label = switch (quota.level) {
          QuotaLevel.green => l.quotaGreen,
          QuotaLevel.yellow => l.quotaYellow,
          QuotaLevel.red => l.quotaRed,
        };
        final total = c.settings.quota;
        return card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.settings.quotaPeriod == QuotaPeriod.week ? l.quotaWeek : l.quotaMonth,
                style: TextStyle(color: colors.ink2, fontSize: 12),
              ),
              const SizedBox(height: 10),
              QuotaProgress(total: total, done: quota.done, color: bg),
              const SizedBox(height: 10),
              Text(
                l.quotaProgress(quota.done, total),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              Text(
                l.quotaStats(quota.done, quota.need, quota.available),
                style: TextStyle(color: colors.ink2, fontSize: 11),
              ),
            ],
          ),
        );
      }
      final end = DateTime(c.today.year, c.today.month, c.today.day + 60);
      DateTime? next;
      for (final d in daysInRange(c.today, end)) {
        if (isOfficeDay(d, c.settings, c.logs, c.holidays)) {
          next = d;
          break;
        }
      }
      return card(
        child: Text(next == null ? l.noUpcoming : l.nextOffice(fmtDate(context, next))),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        Text(
          fmtWeekday(context, c.today),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.1),
        ),
        Text(fmtDate(context, c.today), style: TextStyle(color: colors.ink2)),
        const SizedBox(height: 16),
        hero(),
        if (missing > 0) ...[
          const SizedBox(height: 12),
          card(
            color: colors.sick,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.unfilledBanner(missing),
                    style: TextStyle(color: colors.onSick, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(AppIcons.arrow, color: colors.onSick, size: 18),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        middle(),
        const SizedBox(height: 12),
        SizedBox(
          height: 156,
          child: Row(
            children: [
              Expanded(
                flex: 12,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l.attendance}, ${fmtMonth(context, c.today)}',
                        style: TextStyle(color: colors.ink2, fontSize: 11),
                      ),
                      Text(
                        percent == null ? '-' : '${(percent * 100).round()}%',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: percent ?? 0,
                          minHeight: 6,
                          color: theme.colorScheme.primary,
                          backgroundColor: colors.tint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 10,
                child: Column(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: l.statOffice,
                        value: summary.office,
                        colors: statusColors(colors, DayStatus.office),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: StatTile(
                        label: l.statLeave,
                        value: summary.leave,
                        colors: statusColors(colors, DayStatus.leave),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: StatTile(
                        label: l.statSick,
                        value: summary.sick,
                        colors: statusColors(colors, DayStatus.sick),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
