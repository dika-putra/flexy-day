import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/models.dart';
import '../l10n/l10n.dart';
import 'format.dart';

// Temporary. Replaced by the real Settings screen in milestone 3.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final l = context.l10n;
    final weekdays = shortWeekdays(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        Text(l.tabSettings, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        Text(l.language, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<AppLanguage>(
          segments: [
            ButtonSegment(value: AppLanguage.system, label: Text(l.langSystem)),
            ButtonSegment(value: AppLanguage.id, label: Text(l.langId)),
            ButtonSegment(value: AppLanguage.en, label: Text(l.langEn)),
          ],
          selected: {s.language},
          onSelectionChanged: (v) => notifier.update(s.copyWith(language: v.first)),
        ),
        const SizedBox(height: 24),
        SegmentedButton<WorkMode>(
          segments: [
            ButtonSegment(value: WorkMode.fixed, label: Text(l.modeFixed)),
            ButtonSegment(value: WorkMode.quota, label: Text(l.modeQuota)),
          ],
          selected: {s.mode},
          onSelectionChanged: (v) => notifier.update(s.copyWith(mode: v.first)),
        ),
        const SizedBox(height: 16),
        if (s.mode == WorkMode.fixed)
          Wrap(
            spacing: 8,
            children: [
              for (var d = 1; d <= 5; d++)
                FilterChip(
                  label: Text(weekdays[d - 1]),
                  selected: s.fixedWeekdays.contains(d),
                  onSelected: (on) {
                    final next = {...s.fixedWeekdays};
                    on ? next.add(d) : next.remove(d);
                    notifier.update(s.copyWith(fixedWeekdays: next));
                  },
                ),
            ],
          )
        else ...[
          SegmentedButton<QuotaPeriod>(
            segments: [
              ButtonSegment(value: QuotaPeriod.week, label: Text(l.periodWeek)),
              ButtonSegment(value: QuotaPeriod.month, label: Text(l.periodMonth)),
            ],
            selected: {s.quotaPeriod},
            onSelectionChanged: (v) => notifier.update(s.copyWith(quotaPeriod: v.first)),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: s.quota > 1 ? () => notifier.update(s.copyWith(quota: s.quota - 1)) : null,
              ),
              Text(l.quotaValue(s.quota)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => notifier.update(s.copyWith(quota: s.quota + 1)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
