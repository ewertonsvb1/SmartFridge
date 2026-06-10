import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartfridge_mobile/src/core/network/api_error.dart';
import 'package:smartfridge_mobile/src/features/agenda/data/agenda_repository.dart';
import 'package:smartfridge_mobile/src/features/agenda/presentation/agenda_controller.dart';

String _monthLabel(DateTime month) {
  const monthNames = [
    'Janeiro',
    'Fevereiro',
    'Marco',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${monthNames[month.month - 1]} ${month.year}';
}

DateTime _dateOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

String _dateKey(DateTime dateTime) {
  final date = _dateOnly(dateTime);
  return DateFormat('yyyy-MM-dd').format(date);
}

class AgendaPage extends ConsumerWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(agendaSelectedDateProvider);
    final visibleMonth = ref.watch(agendaVisibleMonthProvider);
    final selectedStatus = ref.watch(agendaStatusFilterProvider);
    final monthEvents = ref.watch(agendaMonthEventsProvider);
    final dayEvents = ref.watch(agendaDayEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Agenda'),
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.home_rounded),
          tooltip: 'Voltar ao inicio',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/agenda/new', extra: selectedDate),
        icon: const Icon(Icons.add),
        label: const Text('Novo evento'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calendario da casa',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102E28),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Consulte o mes, filtre compromissos e mantenha os eventos organizados.',
                  style: TextStyle(
                    color: Color(0xFF61707A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                monthEvents.when(
                  data: (events) {
                    return _CalendarSection(
                      visibleMonth: visibleMonth,
                      selectedDate: selectedDate,
                      events: events,
                      onPreviousMonth: () {
                        final previous =
                            DateTime(visibleMonth.year, visibleMonth.month - 1);
                        ref.read(agendaVisibleMonthProvider.notifier).state =
                            previous;
                        final currentSelected =
                            ref.read(agendaSelectedDateProvider);
                        if (currentSelected.year != previous.year ||
                            currentSelected.month != previous.month) {
                          ref.read(agendaSelectedDateProvider.notifier).state =
                              DateTime(previous.year, previous.month, 1);
                        }
                      },
                      onNextMonth: () {
                        final next =
                            DateTime(visibleMonth.year, visibleMonth.month + 1);
                        ref.read(agendaVisibleMonthProvider.notifier).state =
                            next;
                        final currentSelected =
                            ref.read(agendaSelectedDateProvider);
                        if (currentSelected.year != next.year ||
                            currentSelected.month != next.month) {
                          ref.read(agendaSelectedDateProvider.notifier).state =
                              DateTime(next.year, next.month, 1);
                        }
                      },
                      onSelectDate: (date) {
                        final selected = _dateOnly(date);
                        ref.read(agendaSelectedDateProvider.notifier).state =
                            selected;
                        ref.read(agendaVisibleMonthProvider.notifier).state =
                            DateTime(selected.year, selected.month);
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => _AgendaErrorCard(
                    message: formatApiError(error),
                    onRetry: () => ref.invalidate(agendaMonthEventsProvider),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                selected: selectedStatus == null,
                label: const Text('Todos'),
                onSelected: (_) {
                  ref.read(agendaStatusFilterProvider.notifier).state = null;
                },
              ),
              ...AgendaEventStatus.values.map(
                (status) => FilterChip(
                  selected: selectedStatus == status,
                  label: Text(status.label),
                  onSelected: (_) {
                    ref.read(agendaStatusFilterProvider.notifier).state =
                        status;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Eventos de ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17352E),
            ),
          ),
          const SizedBox(height: 12),
          dayEvents.when(
            data: (events) {
              if (events.isEmpty) {
                return const _EmptyAgendaState();
              }

              return Column(
                children: events
                    .map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AgendaEventCard(event: event),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _AgendaErrorCard(
              message: formatApiError(error),
              onRetry: () => ref.invalidate(agendaDayEventsProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarSection extends StatelessWidget {
  const _CalendarSection({
    required this.visibleMonth,
    required this.selectedDate,
    required this.events,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<AgendaEventModel> events;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final leadingDays = firstDay.weekday - 1;
    final totalSlots = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    final today = DateTime.now();
    final eventsPerDay = <String, int>{};
    final monthDates = List<DateTime?>.generate(totalSlots, (index) {
      if (index < leadingDays || index >= leadingDays + daysInMonth) {
        return null;
      }
      final day = index - leadingDays + 1;
      return DateTime(visibleMonth.year, visibleMonth.month, day);
    });
    final weeks = <List<DateTime?>>[];

    for (final event in events) {
      final key = _dateKey(event.startAt);
      eventsPerDay.update(key, (value) => value + 1, ifAbsent: () => 1);
    }

    for (var index = 0; index < monthDates.length; index += 7) {
      weeks.add(monthDates.sublist(index, index + 7));
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPreviousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                _monthLabel(visibleMonth),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: onNextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final cellHeight = compact ? 82.0 : 104.0;

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.95),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (var index = 0;
                            index < weekdayLabels.length;
                            index++)
                          _WeekdayLabel(
                            label: weekdayLabels[index],
                            isFirstColumn: index == 0,
                          ),
                      ],
                    ),
                    for (var row = 0; row < weeks.length; row++)
                      _CalendarWeekRow(
                        dates: weeks[row],
                        cellHeight: cellHeight,
                        today: today,
                        selectedDate: selectedDate,
                        eventsPerDay: eventsPerDay,
                        onSelectDate: onSelectDate,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel({
    required this.label,
    required this.isFirstColumn,
  });

  final String label;
  final bool isFirstColumn;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          border: Border(
            left: isFirstColumn
                ? BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.95),
                  )
                : BorderSide.none,
            right: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.95),
            ),
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.95),
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _CalendarWeekRow extends StatelessWidget {
  const _CalendarWeekRow({
    required this.dates,
    required this.cellHeight,
    required this.today,
    required this.selectedDate,
    required this.eventsPerDay,
    required this.onSelectDate,
  });

  final List<DateTime?> dates;
  final double cellHeight;
  final DateTime today;
  final DateTime selectedDate;
  final Map<String, int> eventsPerDay;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var column = 0; column < dates.length; column++)
          _CalendarDayCell(
            date: dates[column],
            eventCount: dates[column] == null
                ? 0
                : eventsPerDay[_dateKey(dates[column]!)] ?? 0,
            isSelected: dates[column] != null &&
                selectedDate.year == dates[column]!.year &&
                selectedDate.month == dates[column]!.month &&
                selectedDate.day == dates[column]!.day,
            isToday: dates[column] != null &&
                today.year == dates[column]!.year &&
                today.month == dates[column]!.month &&
                today.day == dates[column]!.day,
            isFirstColumn: column == 0,
            height: cellHeight,
            onTap: dates[column] == null
                ? null
                : () => onSelectDate(dates[column]!),
          ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.eventCount,
    required this.isSelected,
    required this.isToday,
    required this.isFirstColumn,
    required this.height,
    required this.onTap,
  });

  final DateTime? date;
  final int eventCount;
  final bool isSelected;
  final bool isToday;
  final bool isFirstColumn;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOutsideMonth = date == null;
    final hasEvent = eventCount > 0;
    final cellFill = isOutsideMonth
        ? colorScheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.28 : 0.5,
          )
        : isSelected
            ? colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.18)
            : hasEvent
                ? colorScheme.primaryContainer.withValues(
                    alpha: isDark ? 0.5 : 0.75,
                  )
                : colorScheme.surface;
    final borderColor = colorScheme.outlineVariant.withValues(
      alpha: isDark ? 0.95 : 1,
    );
    final dayTextColor = isOutsideMonth
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
        : isSelected
            ? colorScheme.primary
            : colorScheme.onSurface;
    final eventBandColor = isSelected
        ? colorScheme.primary.withValues(alpha: isDark ? 0.38 : 0.22)
        : colorScheme.primary.withValues(alpha: isDark ? 0.34 : 0.16);
    final eventTextColor =
        isSelected ? colorScheme.primary : colorScheme.onPrimaryContainer;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            key: ValueKey(
              'agenda-day-${date == null ? 'outside' : _dateKey(date!)}',
            ),
            height: height,
            decoration: BoxDecoration(
              color: cellFill,
              border: Border(
                left: isFirstColumn
                    ? BorderSide(color: borderColor, width: 1)
                    : BorderSide.none,
                right: BorderSide(color: borderColor, width: 1),
                bottom: BorderSide(color: borderColor, width: 1),
                top: BorderSide.none,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        date == null ? '' : '${date!.day}',
                        style: TextStyle(
                          color: dayTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      if (hasEvent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: eventBandColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            eventCount == 1 ? '1' : '$eventCount',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: eventTextColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (hasEvent)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: eventBandColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.primary.withValues(
                            alpha: isDark ? 0.5 : 0.22,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_rounded,
                            size: 13,
                            color: eventTextColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              eventCount == 1
                                  ? '1 evento'
                                  : '$eventCount eventos',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: eventTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isToday)
                    Container(
                      width: 18,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
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

class _AgendaEventCard extends ConsumerWidget {
  const _AgendaEventCard({required this.event});

  final AgendaEventModel event;

  Color _accentColor() {
    switch (event.status) {
      case AgendaEventStatus.completed:
        return const Color(0xFF2F7D32);
      case AgendaEventStatus.canceled:
        return const Color(0xFFB42318);
      case AgendaEventStatus.scheduled:
        return const Color(0xFF0E7C7B);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = _accentColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('agenda-event-card-${event.id}'),
        onTap: () => context.push('/agenda/edit', extra: event),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      key: ValueKey('agenda-event-title-${event.id}'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF17352E),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    key: ValueKey('agenda-event-menu-${event.id}'),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await context.push('/agenda/edit', extra: event);
                        return;
                      }

                      if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Excluir evento'),
                                content: const Text(
                                    'Deseja remover este evento da Agenda?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Excluir'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (!confirmed) {
                          return;
                        }

                        try {
                          await ref
                              .read(agendaRepositoryProvider)
                              .delete(event.id);
                          invalidateAgendaProviders(ref);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Evento excluido com sucesso.')),
                            );
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(formatApiError(error))),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Excluir'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _InfoPill(
                    icon: Icons.schedule_outlined,
                    label: event.timeRangeLabel,
                    color: const Color(0xFFE7F7F6),
                    textColor: const Color(0xFF0E615F),
                  ),
                  _InfoPill(
                    icon: Icons.flag_outlined,
                    label: event.status.label,
                    color: accentColor.withValues(alpha: 0.12),
                    textColor: accentColor,
                  ),
                ],
              ),
              if (event.description.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  event.description,
                  style: const TextStyle(
                    color: Color(0xFF5F6C77),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAgendaState extends StatelessWidget {
  const _EmptyAgendaState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 36, color: Color(0xFF6B7280)),
          SizedBox(height: 12),
          Text(
            'Nenhum evento para a data selecionada.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF44505A),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaErrorCard extends StatelessWidget {
  const _AgendaErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Erro ao carregar Agenda',
            style: TextStyle(
              color: Color(0xFF9F2D2D),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF7A4343)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
