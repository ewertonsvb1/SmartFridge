import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartfridge_mobile/src/core/network/api_error.dart';
import 'package:smartfridge_mobile/src/features/house_bills/data/house_bills_repository.dart';
import 'package:smartfridge_mobile/src/features/house_bills/presentation/house_bills_controller.dart';

class HouseBillFormPage extends ConsumerStatefulWidget {
  const HouseBillFormPage({
    super.key,
    this.initialBill,
  });

  final HouseBillModel? initialBill;

  @override
  ConsumerState<HouseBillFormPage> createState() => _HouseBillFormPageState();
}

class _HouseBillFormPageState extends ConsumerState<HouseBillFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  late DateTime _dueDate;

  bool get _isEditing => widget.initialBill != null;

  @override
  void initState() {
    super.initState();
    final initialBill = widget.initialBill;
    if (initialBill != null) {
      _descriptionController.text = initialBill.description;
      _amountController.text = initialBill.amount.toStringAsFixed(2);
      _categoryController.text = initialBill.category;
      _dueDate = initialBill.dueDate;
      return;
    }

    _dueDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String _dueDateLabel() {
    return DateFormat('dd/MM/yyyy').format(_dueDate);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawAmount = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Informe um valor valido maior que zero.')),
      );
      return;
    }

    final mutation = ref.read(houseBillsMutationProvider.notifier);

    try {
      if (_isEditing) {
        await mutation.update(
          id: widget.initialBill!.id,
          description: _descriptionController.text.trim(),
          amount: amount,
          dueDate: _dueDate,
          category: _categoryController.text.trim(),
        );
      } else {
        await mutation.create(
          description: _descriptionController.text.trim(),
          amount: amount,
          dueDate: _dueDate,
          category: _categoryController.text.trim(),
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Conta atualizada com sucesso.'
                : 'Conta criada com sucesso.',
          ),
        ),
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatApiError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(houseBillsMutationProvider);
    final loading = mutationState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Conta' : 'Nova Conta'),
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
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descricao'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe a descricao';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o valor';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            const SizedBox(height: 12),
            InkWell(
              key: const ValueKey('house-bill-due-date-field'),
              onTap: loading ? null : _pickDueDate,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Vencimento',
                  suffixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(_dueDateLabel()),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: loading ? null : _save,
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
