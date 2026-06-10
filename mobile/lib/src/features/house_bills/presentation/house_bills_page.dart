import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartfridge_mobile/src/core/network/api_error.dart';
import 'package:smartfridge_mobile/src/features/house_bills/data/house_bills_repository.dart';
import 'package:smartfridge_mobile/src/features/house_bills/presentation/house_bills_controller.dart';

class HouseBillsPage extends ConsumerWidget {
  const HouseBillsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(houseBillsDashboardProvider);
    final bills = ref.watch(houseBillsListProvider);
    final selectedStatus = ref.watch(houseBillsStatusFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        title: const Text('Contas da Casa'),
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.home_rounded),
          tooltip: 'Voltar ao inicio',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('house-bills-add-button'),
        onPressed: () => context.push('/house-bills/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nova conta'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          invalidateHouseBillsProviders(ref);
          await Future.wait([
            ref.read(houseBillsDashboardProvider.future),
            ref.read(houseBillsListProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const _HouseBillsIntroCard(),
            const SizedBox(height: 16),
            dashboard.when(
              data: (data) => _HouseBillsDashboardSection(dashboard: data),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _HouseBillsErrorCard(
                title: 'Erro ao carregar dashboard financeiro',
                message: formatApiError(error),
                onRetry: () => ref.invalidate(houseBillsDashboardProvider),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  selected: selectedStatus == null,
                  label: const Text('Todas'),
                  onSelected: (_) {
                    ref.read(houseBillsStatusFilterProvider.notifier).state =
                        null;
                  },
                ),
                ...HouseBillStatus.values.map(
                  (status) => FilterChip(
                    selected: selectedStatus == status,
                    label: Text(status.label),
                    onSelected: (_) {
                      ref.read(houseBillsStatusFilterProvider.notifier).state =
                          status;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            bills.when(
              data: (items) {
                if (items.isEmpty) {
                  return const _HouseBillsEmptyState();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedStatus == null
                          ? 'Contas cadastradas'
                          : 'Contas ${selectedStatus.label.toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2F241A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map(
                      (bill) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _HouseBillCard(bill: bill),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _HouseBillsErrorCard(
                title: 'Erro ao carregar contas',
                message: formatApiError(error),
                onRetry: () => ref.invalidate(houseBillsListProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HouseBillsIntroCard extends StatelessWidget {
  const _HouseBillsIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1DEC2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Painel financeiro da casa',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4C3310),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Acompanhe contas abertas, vencidas e pagas. Adicione ou edite contas sem sair do modulo.',
            style: TextStyle(
              color: Color(0xFF6E5B3E),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HouseBillsDashboardSection extends StatelessWidget {
  const _HouseBillsDashboardSection({required this.dashboard});

  final HouseBillsDashboardDetailModel dashboard;

  String _currency(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Em aberto',
                value: '${dashboard.openCount}',
                note: _currency(dashboard.openAmount),
                valueKey: const ValueKey('house-bills-open-count'),
                noteKey: const ValueKey('house-bills-open-amount'),
                color: const Color(0xFFFFF7E8),
                accentColor: const Color(0xFFB7791F),
                icon: Icons.schedule_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Vencidas',
                value: '${dashboard.overdueCount}',
                note: _currency(dashboard.overdueAmount),
                valueKey: const ValueKey('house-bills-overdue-count'),
                noteKey: const ValueKey('house-bills-overdue-amount'),
                color: const Color(0xFFFFEFEF),
                accentColor: const Color(0xFFB42318),
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Pagas',
                value: '${dashboard.paidCount}',
                note: _currency(dashboard.paidAmount),
                valueKey: const ValueKey('house-bills-paid-count'),
                noteKey: const ValueKey('house-bills-paid-amount'),
                color: const Color(0xFFEAF4EF),
                accentColor: const Color(0xFF2F7D32),
                icon: Icons.task_alt_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Total',
                value: '${dashboard.totalCount}',
                note: _currency(dashboard.totalAmount),
                valueKey: const ValueKey('house-bills-total-count'),
                noteKey: const ValueKey('house-bills-total-amount'),
                color: Colors.white,
                accentColor: const Color(0xFF4C3310),
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.note,
    required this.valueKey,
    required this.noteKey,
    required this.color,
    required this.accentColor,
    required this.icon,
  });

  final String title;
  final String value;
  final String note;
  final Key valueKey;
  final Key noteKey;
  final Color color;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6A5B4B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            key: valueKey,
            style: TextStyle(
              color: accentColor,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            key: noteKey,
            style: const TextStyle(
              color: Color(0xFF6A5B4B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HouseBillCard extends ConsumerWidget {
  const _HouseBillCard({required this.bill});

  final HouseBillModel bill;

  Color _accentColor() {
    switch (bill.status) {
      case HouseBillStatus.open:
        return const Color(0xFFB7791F);
      case HouseBillStatus.overdue:
        return const Color(0xFFB42318);
      case HouseBillStatus.paid:
        return const Color(0xFF2F7D32);
    }
  }

  String _currency(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  Future<void> _markAsPaid(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(houseBillsMutationProvider.notifier).markAsPaid(bill.id);
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta marcada como paga.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatApiError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = _accentColor();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('house-bill-card-${bill.id}'),
        onTap: () => context.push('/house-bills/edit', extra: bill),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      bill.description,
                      key: ValueKey('house-bill-title-${bill.id}'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2F241A),
                      ),
                    ),
                  ),
                  _BillInfoPill(
                    icon: Icons.flag_outlined,
                    label: bill.status.label,
                    color: accentColor.withValues(alpha: 0.12),
                    textColor: accentColor,
                  ),
                  IconButton(
                    tooltip: 'Editar conta',
                    onPressed: () =>
                        context.push('/house-bills/edit', extra: bill),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _BillInfoPill(
                    icon: Icons.payments_outlined,
                    label: _currency(bill.amount),
                    color: const Color(0xFFF5F1EA),
                    textColor: const Color(0xFF6E5B3E),
                  ),
                  _BillInfoPill(
                    icon: Icons.event_outlined,
                    label: 'Vence em ${bill.dueDateLabel}',
                    color: const Color(0xFFF5F1EA),
                    textColor: const Color(0xFF6E5B3E),
                  ),
                  if (bill.category.trim().isNotEmpty)
                    _BillInfoPill(
                      icon: Icons.label_outline_rounded,
                      label: bill.category,
                      color: const Color(0xFFF5F1EA),
                      textColor: const Color(0xFF6E5B3E),
                    ),
                ],
              ),
              if (bill.status != HouseBillStatus.paid) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    key: ValueKey('house-bill-pay-button-${bill.id}'),
                    onPressed: () => _markAsPaid(context, ref),
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('Pagas'),
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

class _BillInfoPill extends StatelessWidget {
  const _BillInfoPill({
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

class _HouseBillsEmptyState extends StatelessWidget {
  const _HouseBillsEmptyState();

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
          Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF8B7A62)),
          SizedBox(height: 12),
          Text(
            'Nenhuma conta encontrada para o filtro selecionado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF5E5244),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HouseBillsErrorCard extends StatelessWidget {
  const _HouseBillsErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
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
          Text(
            title,
            style: const TextStyle(
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
