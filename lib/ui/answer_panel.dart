import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import '../domain/schedule.dart';
import '../l10n/l10n.dart';
import 'format.dart';
import 'icons.dart';
import 'theme.dart';

Future<void> showAnswerSheet(BuildContext context, DateTime date) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fmtDateLong(ctx, date),
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              AnswerPanel(date: date, onSaved: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );

class AnswerPanel extends ConsumerStatefulWidget {
  const AnswerPanel({super.key, required this.date, this.onHero = false, this.onSaved});

  final DateTime date;
  final bool onHero;
  final VoidCallback? onSaved;

  @override
  ConsumerState<AnswerPanel> createState() => _AnswerPanelState();
}

class _AnswerPanelState extends ConsumerState<AnswerPanel> {
  DayStatus? _status;
  DateTime? _target;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final log = ref.read(ctxProvider).logFor(widget.date);
    _status = log?.status;
    _target = log?.rescheduledTo;
    _note.text = log?.note ?? '';
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<DateTime> _candidates(Ctx c) {
    final tomorrow = DateTime(c.today.year, c.today.month, c.today.day + 1);
    final list = daysInRange(
      tomorrow,
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day + 45),
    ).where((d) => canRescheduleTo(d, c.today, c.holidays)).take(10).toList();
    if (_target != null && !list.contains(_target) && canRescheduleTo(_target!, c.today, c.holidays)) {
      list.insert(0, _target!);
    }
    return list;
  }

  Future<void> _save() async {
    final note = _note.text.trim();
    await ref.read(logRepositoryProvider).upsert(DayLog(
          date: widget.date,
          status: _status!,
          note: note.isEmpty ? null : note,
          rescheduledTo: _status == DayStatus.rescheduled ? _target : null,
        ));
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(ctxProvider);
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final colors = context.colors;
    final hero = widget.onHero;
    final tileBg = hero ? const Color(0x33FFFFFF) : colors.tint;
    final tileFg = hero ? Colors.white : colors.ink;
    final selBg = hero ? Colors.white : cs.primary;
    final selFg = hero ? cs.primary : cs.onPrimary;

    final canMove = c.settings.mode == WorkMode.fixed &&
        (c.logFor(widget.date)?.status == DayStatus.rescheduled ||
            isOfficeDay(widget.date, c.settings, c.logs, c.holidays));
    final entries = [
      (DayStatus.office, AppIcons.office, l.answerOffice),
      if (canMove) (DayStatus.rescheduled, AppIcons.move, l.answerMove),
      (DayStatus.leave, AppIcons.leave, l.answerLeave),
      (DayStatus.sick, AppIcons.sick, l.answerSick),
    ];
    final canSave = _status != null && (_status != DayStatus.rescheduled || _target != null);
    final weekdays = shortWeekdays(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: entries.length == 4 ? 2 : 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: entries.length == 4 ? 1.9 : 1.15,
          children: [
            for (final e in entries)
              GestureDetector(
                onTap: () => setState(() => _status = e.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: _status == e.$1 ? selBg : tileBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(e.$2, size: 24, color: _status == e.$1 ? selFg : tileFg),
                      const SizedBox(height: 4),
                      Text(
                        e.$3,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _status == e.$1 ? selFg : tileFg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: _status == null
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_status == DayStatus.rescheduled) ...[
                      const SizedBox(height: 14),
                      Text(
                        l.moveTo,
                        style: TextStyle(color: tileFg, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final d in _candidates(c))
                              GestureDetector(
                                onTap: () => setState(() => _target = d),
                                child: Container(
                                  width: 52,
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _target == d ? selBg : tileBg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        weekdays[d.weekday - 1],
                                        style: TextStyle(fontSize: 11, color: _target == d ? selFg : tileFg),
                                      ),
                                      Text(
                                        '${d.day}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: _target == d ? selFg : tileFg,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _note,
                      style: TextStyle(color: tileFg),
                      decoration: InputDecoration(
                        hintText: l.noteHint,
                        hintStyle: TextStyle(color: hero ? const Color(0xB3FFFFFF) : colors.ink2),
                        filled: true,
                        fillColor: tileBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: canSave ? _save : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: hero ? Colors.white : cs.primary,
                        foregroundColor: hero ? cs.primary : cs.onPrimary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(l.save, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
