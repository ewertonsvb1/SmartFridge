import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfridge_mobile/src/features/dashboard/data/dashboard_repository.dart';
import 'package:smartfridge_mobile/src/features/dashboard/presentation/dashboard_controller.dart';

class HomeHubPage extends ConsumerWidget {
  const HomeHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(globalDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F3),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          children: [
            const Row(
              children: [
                Icon(Icons.home_work_rounded,
                    color: Color(0xFF44A169), size: 30),
                SizedBox(width: 8),
                Text(
                  'SmartHouse',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A3028),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Sua casa em um só lugar',
              style: TextStyle(
                color: Color(0xFF6F7781),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            dashboard.when(
              data: (data) => _DashboardHighlights(dashboard: data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _DashboardError(message: '$error'),
            ),
            const SizedBox(height: 14),
            _HubCard(
              title: 'Geladeira',
              subtitle: _fridgeSubtitle(dashboard.valueOrNull?.fridge),
              icon: Icons.kitchen_rounded,
              accentColor: const Color(0xFF2F7F68),
              backgroundColor: Colors.white,
              trailing: FilledButton(
                onPressed: () => context.push('/fridge'),
                child: const Text('Abrir'),
              ),
            ),
            const SizedBox(height: 14),
            _HubCard(
              title: 'Agenda',
              subtitle: _agendaSubtitle(),
              icon: Icons.event_note_rounded,
              accentColor: const Color(0xFF3366CC),
              backgroundColor: Colors.white,
              trailing: FilledButton(
                onPressed: () => context.push('/agenda'),
                child: const Text('Abrir'),
              ),
            ),
            const SizedBox(height: 14),
            _HubCard(
              title: 'Contas da Casa',
              subtitle: _houseBillsSubtitle(dashboard.valueOrNull?.houseBills),
              icon: Icons.receipt_long_rounded,
              accentColor: dashboard.valueOrNull?.houseBills.implemented == true
                  ? const Color(0xFF935E0B)
                  : const Color(0xFF6B7280),
              backgroundColor: const Color(0xFFF8FAFC),
              trailing: FilledButton(
                onPressed: () => context.push('/house-bills'),
                child: const Text('Abrir'),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4EF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Atalho rapido',
                    style: TextStyle(
                      color: Color(0xFF1B4332),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Acesse a Geladeira para manter os itens, compras e notificacoes da casa sob controle.',
                    style: TextStyle(
                      color: Color(0xFF355347),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fridgeSubtitle(FridgeDashboardModel? fridge) {
    if (fridge == null) {
      return 'Produtos, compras e notificacoes da casa';
    }
    return '${fridge.total} itens, ${fridge.expired} vencidos e ${fridge.nearExpiration} proximos do vencimento';
  }

  String _agendaSubtitle() {
    return 'Calendario visual, consultas por data e CRUD de eventos da casa';
  }

  String _houseBillsSubtitle(HouseBillsDashboardModel? houseBills) {
    if (houseBills == null) {
      return 'Dashboard financeiro e lista de contas da casa';
    }
    if (!houseBills.implemented) {
      return 'Dashboard financeiro e lista de contas da casa';
    }
    return '${houseBills.totalOpen} contas abertas e ${houseBills.overdue} vencidas';
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102E28),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF61707A),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _DashboardHighlights extends StatelessWidget {
  const _DashboardHighlights({required this.dashboard});

  final GlobalDashboardModel dashboard;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Itens na geladeira',
            value: '${dashboard.fridge.total}',
            note: '${dashboard.fridge.nearExpiration} proximos',
            color: const Color(0xFFEAF4EF),
            accentColor: const Color(0xFF2F7F68),
            icon: Icons.kitchen_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Agenda',
            value: dashboard.agenda.implemented
                ? '${dashboard.agenda.today}'
                : '--',
            note: dashboard.agenda.implemented ? 'para hoje' : 'em breve',
            color: const Color(0xFFF2F4F8),
            accentColor: const Color(0xFF5B6470),
            icon: Icons.event_note_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Contas da Casa',
            value: dashboard.houseBills.implemented
                ? '${dashboard.houseBills.totalOpen}'
                : '--',
            note: dashboard.houseBills.implemented ? 'em aberto' : 'em breve',
            color: const Color(0xFFF7F2E8),
            accentColor: const Color(0xFF8C6A2A),
            icon: Icons.receipt_long_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.note,
    required this.color,
    required this.accentColor,
    required this.icon,
  });

  final String title;
  final String value;
  final String note;
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF48535E),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(
              color: Color(0xFF61707A),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Erro ao carregar dashboard',
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
        ],
      ),
    );
  }
}
