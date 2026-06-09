import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfridge_mobile/src/core/network/api_error.dart';
import 'package:smartfridge_mobile/src/features/product/data/product_repository.dart';
import 'package:smartfridge_mobile/src/features/product/presentation/product_controller.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.initialProduct});

  final ProductModel? initialProduct;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _manuController = TextEditingController();
  final _expController = TextEditingController();
  bool _loading = false;

  bool get _isEditing => widget.initialProduct != null;

  @override
  void initState() {
    super.initState();
    final product = widget.initialProduct;
    if (product == null) {
      return;
    }

    _nameController.text = product.name;
    _quantityController.text = product.quantity.toString();
    _manuController.text = product.manufactureDate;
    _expController.text = product.expirationDate;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    DateTime initialDate = now;
    if (controller.text.isNotEmpty) {
      initialDate = DateTime.tryParse(controller.text) ?? now;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = _formatDate(picked);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _manuController.dispose();
    _expController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(productRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Produto' : 'Novo Produto'),
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.home_rounded),
          tooltip: 'Voltar ao inicio',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade'),
              validator: (value) {
                final parsed = int.tryParse((value ?? '').trim());
                if (parsed == null || parsed <= 0) {
                  return 'Quantidade deve ser maior que zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _manuController,
              readOnly: true,
              onTap: () => _pickDate(_manuController),
              decoration: InputDecoration(
                labelText: 'Fabricação (yyyy-mm-dd)',
                hintText: 'Selecione no calendário',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month_outlined),
                  onPressed: () => _pickDate(_manuController),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe a data de fabricação';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _expController,
              readOnly: true,
              onTap: () => _pickDate(_expController),
              decoration: InputDecoration(
                labelText: 'Validade (yyyy-mm-dd)',
                hintText: 'Selecione no calendário',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month_outlined),
                  onPressed: () => _pickDate(_expController),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe a data de validade';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;

                      final manufactureDate =
                          DateTime.tryParse(_manuController.text.trim());
                      final expirationDate =
                          DateTime.tryParse(_expController.text.trim());
                      if (manufactureDate == null || expirationDate == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Datas inválidas. Use o seletor de data.')),
                          );
                        }
                        return;
                      }

                      if (expirationDate.isBefore(manufactureDate)) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Validade não pode ser antes da fabricação.')),
                          );
                        }
                        return;
                      }

                      setState(() => _loading = true);
                      try {
                        if (_isEditing) {
                          await repo.update(
                            id: widget.initialProduct!.id,
                            name: _nameController.text.trim(),
                            quantity:
                                int.parse(_quantityController.text.trim()),
                            manufactureDate: _manuController.text.trim(),
                            expirationDate: _expController.text.trim(),
                          );
                        } else {
                          await repo.create(
                            name: _nameController.text.trim(),
                            quantity:
                                int.parse(_quantityController.text.trim()),
                            manufactureDate: _manuController.text.trim(),
                            expirationDate: _expController.text.trim(),
                          );
                        }

                        ref.invalidate(productListProvider);
                        ref.invalidate(dashboardProvider);
                        ref.invalidate(expiredProductsProvider);
                        ref.invalidate(nearExpirationProductsProvider);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isEditing
                                    ? 'Produto atualizado com sucesso.'
                                    : 'Produto criado com sucesso.',
                              ),
                            ),
                          );
                          context.pop(true);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(formatApiError(e))),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Salvar'),
            )
          ],
        ),
      ),
    );
  }
}
