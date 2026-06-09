import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/features/agenda/data/agenda_repository.dart';
import 'package:smartfridge_mobile/src/features/dashboard/presentation/dashboard_controller.dart';

DateTime _dateOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

final agendaSelectedDateProvider = StateProvider<DateTime>((ref) {
  return _dateOnly(DateTime.now());
});

final agendaVisibleMonthProvider = StateProvider<DateTime>((ref) {
  final selectedDate = ref.watch(agendaSelectedDateProvider);
  return DateTime(selectedDate.year, selectedDate.month);
});

final agendaStatusFilterProvider = StateProvider<AgendaEventStatus?>((ref) {
  return null;
});

final agendaDayEventsProvider =
    FutureProvider<List<AgendaEventModel>>((ref) async {
  final selectedDate = ref.watch(agendaSelectedDateProvider);
  final status = ref.watch(agendaStatusFilterProvider);
  return ref.watch(agendaRepositoryProvider).list(
        date: selectedDate,
        status: status,
      );
});

final agendaMonthEventsProvider =
    FutureProvider<List<AgendaEventModel>>((ref) async {
  final visibleMonth = ref.watch(agendaVisibleMonthProvider);
  final status = ref.watch(agendaStatusFilterProvider);
  final startDate = DateTime(visibleMonth.year, visibleMonth.month, 1);
  final endDate = DateTime(visibleMonth.year, visibleMonth.month + 1, 0);
  return ref.watch(agendaRepositoryProvider).list(
        startDate: startDate,
        endDate: endDate,
        status: status,
      );
});

void invalidateAgendaProviders(WidgetRef ref) {
  ref.invalidate(agendaDayEventsProvider);
  ref.invalidate(agendaMonthEventsProvider);
  ref.invalidate(globalDashboardProvider);
}
