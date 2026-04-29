import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartfridge_mobile/src/core/network/api_error.dart';
import 'package:smartfridge_mobile/src/features/auth/presentation/auth_controller.dart';
import 'package:smartfridge_mobile/src/features/notification/data/notification_repository.dart';
import 'package:smartfridge_mobile/src/features/product/data/product_repository.dart';
import 'package:smartfridge_mobile/src/features/product/presentation/product_controller.dart';
import 'package:smartfridge_mobile/src/features/shopping/data/shopping_repository.dart';
import 'package:smartfridge_mobile/src/features/shopping/presentation/shopping_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  Color _statusDotColor(String status) {
    switch (status) {
      case 'EXPIRED':
        return const Color(0xFFDF3F46);
      case 'NEAR_EXPIRATION':
        return const Color(0xFFF08C00);
      default:
        return const Color(0xFF1B8F5A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _ProductsTab(statusDotColor: _statusDotColor),
      const _FiltersTab(),
      const _ShoppingTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F3),
      body: IndexedStack(index: _currentIndex, children: tabs),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/product/new'),
              backgroundColor: const Color(0xFF2F7F68),
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 42),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 84,
              backgroundColor: Colors.white,
              indicatorColor: Colors.transparent,
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  size: 28,
                  color: selected ? const Color(0xFF2F7F68) : const Color(0xFF808890),
                );
              }),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return TextStyle(
                  color: selected ? const Color(0xFF2F7F68) : const Color(0xFF6E7580),
                  fontSize: 17,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.kitchen_rounded), label: 'Produtos'),
                NavigationDestination(icon: Icon(Icons.filter_alt_rounded), label: 'Filtros'),
                NavigationDestination(icon: Icon(Icons.shopping_cart_rounded), label: 'Compras'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab({required this.statusDotColor});

  final Color Function(String) statusDotColor;

  IconData _productIcon(String productName) {
    final normalized = productName.toLowerCase();
    if (normalized.contains('pao') || normalized.contains('pão')) {
      return Icons.bakery_dining_rounded;
    }
    if (normalized.contains('banana')) {
      return Icons.set_meal_rounded;
    }
    if (normalized.contains('leite')) {
      return Icons.local_drink_rounded;
    }
    return Icons.inventory_2_rounded;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'EXPIRED':
        return 'Vencido';
      case 'NEAR_EXPIRATION':
        return 'Próximo';
      default:
        return 'Fresco';
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'EXPIRED':
        return const Color(0xFFF9E6E8);
      case 'NEAR_EXPIRATION':
        return const Color(0xFFFBEEDC);
      default:
        return const Color(0xFFE7F2E9);
    }
  }

  Color _cardTint(String status) {
    switch (status) {
      case 'EXPIRED':
        return const Color(0xFFFCEFEF);
      case 'NEAR_EXPIRATION':
        return const Color(0xFFFBF5E7);
      default:
        return const Color(0xFFEFF6EF);
    }
  }

  String _formatDate(String raw) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  Future<void> _deleteProduct(
    BuildContext context,
    WidgetRef ref,
    ProductRepository repository,
    ProductModel product,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir produto'),
          content: Text('Deseja excluir "${product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await repository.delete(product.id);
      ref.invalidate(productListProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(expiredProductsProvider);
      ref.invalidate(nearExpirationProductsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto excluído com sucesso.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatApiError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListProvider);
    final dashboard = ref.watch(dashboardProvider);
    final sort = ref.watch(_productSortProvider);
    final productRepository = ref.watch(productRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
      children: [
        const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.eco, color: Color(0xFF44A169), size: 28),
                      SizedBox(width: 6),
                      Text(
                        'SmartFridge',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A3028),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gerencie o que tem na sua geladeira',
                    style: TextStyle(
                      color: Color(0xFF6F7781),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _IconActionButton(),
          ],
        ),
        const SizedBox(height: 22),
        dashboard.when(
          data: (d) => Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total de itens',
                  value: '${d['total'] ?? 0}',
                  cardColor: const Color(0xFFEFF6EF),
                  iconBg: const Color(0xFFCAEACD),
                  iconColor: const Color(0xFF26865D),
                  icon: Icons.kitchen_rounded,
                  valueColor: const Color(0xFF26865D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Vencidos',
                  value: '${d['expired'] ?? 0}',
                  cardColor: const Color(0xFFFCEFF1),
                  iconBg: const Color(0xFFFCD7D8),
                  iconColor: const Color(0xFFE95B5F),
                  icon: Icons.event_busy_rounded,
                  valueColor: const Color(0xFFE04346),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Próximos a vencer',
                  value: '${d['nearExpiration'] ?? 0}',
                  cardColor: const Color(0xFFFBF5E8),
                  iconBg: const Color(0xFFF8E5BE),
                  iconColor: const Color(0xFFEC980D),
                  icon: Icons.schedule_rounded,
                  valueColor: const Color(0xFFEC8F00),
                ),
              ),
            ],
          ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Erro dashboard: $e'),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Seus itens',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2F28),
                ),
              ),
            ),
            const Text('Ordenar: ', style: TextStyle(color: Color(0xFF4D545F), fontSize: 18)),
            PopupMenuButton<_ProductSortOption>(
              tooltip: 'Ordenar produtos',
              initialValue: sort,
              onSelected: (selected) => ref.read(_productSortProvider.notifier).state = selected,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _ProductSortOption.mostRecent,
                  child: Text('Mais recentes'),
                ),
                PopupMenuItem(
                  value: _ProductSortOption.oldest,
                  child: Text('Mais antigos'),
                ),
                PopupMenuItem(
                  value: _ProductSortOption.expirationSoonest,
                  child: Text('Validade mais próxima'),
                ),
              ],
              child: Row(
                children: [
                  Text(
                    sort.label,
                    style: const TextStyle(
                      color: Color(0xFF23352E),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more_rounded, color: Color(0xFF5F6873), size: 24),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        products.when(
          data: (list) {
            final sorted = [...list]..sort((a, b) {
              if (sort == _ProductSortOption.expirationSoonest) {
                final da = DateTime.tryParse(a.expirationDate) ?? DateTime(9999);
                final db = DateTime.tryParse(b.expirationDate) ?? DateTime(9999);
                return da.compareTo(db);
              }
              if (sort == _ProductSortOption.oldest) {
                return a.id.compareTo(b.id);
              }
              return b.id.compareTo(a.id);
            });

            return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: sorted
                .map(
                  (p) => Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 18,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: _cardTint(p.status),
                            borderRadius: BorderRadius.circular(43),
                          ),
                          child: Icon(
                            _productIcon(p.name),
                            size: 42,
                            color: statusDotColor(p.status),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF102E28),
                                ),
                              ),
                              const SizedBox(height: 6),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 14),
                                  children: [
                                    const TextSpan(
                                      text: 'Qtd: ',
                                      style: TextStyle(
                                        color: Color(0xFF6A7380),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${p.quantity}',
                                      style: const TextStyle(
                                        color: Color(0xFF4B5561),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: '  •  Validade: ',
                                      style: TextStyle(
                                        color: Color(0xFF6A7380),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: _formatDate(p.expirationDate),
                                      style: TextStyle(
                                        color: statusDotColor(p.status),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: _statusBg(p.status),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: statusDotColor(p.status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _statusLabel(p.status),
                                    style: TextStyle(
                                      color: statusDotColor(p.status),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Editar produto',
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Color(0xFF5E6874),
                                  ),
                                  onPressed: () async {
                                    final changed = await context.push<bool>(
                                      '/product/edit',
                                      extra: p,
                                    );
                                    if (changed == true) {
                                      ref.invalidate(productListProvider);
                                      ref.invalidate(dashboardProvider);
                                      ref.invalidate(expiredProductsProvider);
                                      ref.invalidate(nearExpirationProductsProvider);
                                    }
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Excluir produto',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFB3393F),
                                  ),
                                  onPressed: () => _deleteProduct(
                                    context,
                                    ref,
                                    productRepository,
                                    p,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
                    .toList(),
                  );
                  },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 26),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Erro produtos: $e'),
        ),
        const SizedBox(height: 92),
      ],
    );
  }
}

class _IconActionButton extends ConsumerWidget {
  const _IconActionButton();

  String _formatDate(String raw) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _notificationLabel(NotificationItem item) {
    if (item.type == 'EXPIRED') {
      return 'Produto vencido';
    }
    if (item.type == 'NEAR_EXPIRATION') {
      return 'Próximo do vencimento';
    }
    return 'Notificação';
  }

  Future<void> _openNotifications(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          child: Consumer(
            builder: (_, modalRef, __) {
              final notifications = modalRef.watch(notificationsProvider);
              return SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.6,
                child: notifications.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('Sem notificações até o momento.'),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notificações',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              final item = items[index];
                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                tileColor: Colors.white,
                                title: Text(item.productName),
                                subtitle: Text(
                                  '${_notificationLabel(item)} • Validade ${_formatDate(item.productExpirationDate)}',
                                ),
                                leading: Icon(
                                  item.type == 'EXPIRED'
                                      ? Icons.error_outline
                                      : Icons.schedule_rounded,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text(formatApiError(e))),
                ),
              );
            },
          ),
        );
      },
    );

    ref.invalidate(notificationsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final hasNotification = notifications.maybeWhen(
      data: (items) => items.isNotEmpty,
      orElse: () => false,
    );

    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onLongPress: () async {
          await ref.read(authControllerProvider.notifier).logout();
          if (context.mounted) {
            context.go('/login');
          }
        },
        onTap: () => _openNotifications(context, ref),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            children: [
              const Center(
                child: Icon(Icons.notifications_none_rounded, color: Color(0xFF1A3931), size: 33),
              ),
              if (hasNotification)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E986B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.cardColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.valueColor,
  });

  final String title;
  final String value;
  final Color cardColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF48535E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ProductSortOption {
  mostRecent,
  oldest,
  expirationSoonest,
}

extension on _ProductSortOption {
  String get label {
    switch (this) {
      case _ProductSortOption.mostRecent:
        return 'Mais recentes';
      case _ProductSortOption.oldest:
        return 'Mais antigos';
      case _ProductSortOption.expirationSoonest:
        return 'Validade mais próxima';
    }
  }
}

final _productSortProvider = StateProvider<_ProductSortOption>((_) {
  return _ProductSortOption.mostRecent;
});

class _FiltersTab extends ConsumerWidget {
  const _FiltersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expired = ref.watch(expiredProductsProvider);
    final near = ref.watch(nearExpirationProductsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      children: [
        const Text(
          'Filtros',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF0F2F28)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: expired.when(
            data: (list) => Text('Vencidos: ${list.length}', style: const TextStyle(fontSize: 18)),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Erro: $e'),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: near.when(
            data: (list) => Text('Próximos a vencer: ${list.length}', style: const TextStyle(fontSize: 18)),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Erro: $e'),
          ),
        ),
      ],
    );
  }
}

class _ShoppingTab extends ConsumerWidget {
  const _ShoppingTab();

  Future<_ShoppingItemDraft?> _openItemForm(
    BuildContext context, {
    String? initialName,
    int? initialQuantity,
  }) async {
    final nameController = TextEditingController(text: initialName ?? '');
    final quantityController = TextEditingController(
      text: (initialQuantity ?? 1).toString(),
    );

    final result = await showDialog<_ShoppingItemDraft>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(initialName == null ? 'Novo item' : 'Editar item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome do item'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final quantity = int.tryParse(quantityController.text.trim());
                if (name.isEmpty || quantity == null || quantity <= 0) {
                  return;
                }
                Navigator.of(dialogContext).pop(
                  _ShoppingItemDraft(name: name, quantity: quantity),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    quantityController.dispose();
    return result;
  }

  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    ShoppingRepository repo,
    ShoppingItem item,
  ) async {
    final draft = await _openItemForm(
      context,
      initialName: item.name,
      initialQuantity: item.quantity,
    );

    if (draft == null) {
      return;
    }

    try {
      await repo.update(ShoppingItem(
        id: item.id,
        name: draft.name,
        quantity: draft.quantity,
        checked: item.checked,
      ));
      ref.invalidate(shoppingListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item atualizado com sucesso.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatApiError(e))),
        );
      }
    }
  }

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    ShoppingRepository repo,
    ShoppingItem item,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir item'),
          content: Text('Deseja excluir "${item.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await repo.delete(item.id);
      ref.invalidate(shoppingListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removido da lista.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatApiError(e))),
        );
      }
    }
  }

  Future<void> _createItem(
    BuildContext context,
    WidgetRef ref,
    ShoppingRepository repo,
  ) async {
    final draft = await _openItemForm(context);
    if (draft == null) {
      return;
    }

    try {
      await repo.create(draft.name, draft.quantity);
      ref.invalidate(shoppingListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item adicionado à lista.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatApiError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(shoppingListProvider);
    final repo = ref.watch(shoppingRepositoryProvider);

    return list.when(
      data: (items) => ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        children: [
          const Text(
            'Compras',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF0F2F28)),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Checkbox(
                  value: item.checked,
                  onChanged: (v) async {
                    try {
                      await repo.update(ShoppingItem(
                        id: item.id,
                        name: item.name,
                        quantity: item.quantity,
                        checked: v ?? false,
                      ));
                      ref.invalidate(shoppingListProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(formatApiError(e))),
                        );
                      }
                    }
                  },
                ),
                title: Text(item.name),
                subtitle: Text('Qtd: ${item.quantity}'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editItem(context, ref, repo, item),
                    ),
                    IconButton(
                      tooltip: 'Excluir',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteItem(context, ref, repo, item),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => _createItem(context, ref, repo),
            child: const Text('Adicionar item'),
          )
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
    );
  }
}

class _ShoppingItemDraft {
  _ShoppingItemDraft({required this.name, required this.quantity});

  final String name;
  final int quantity;
}
