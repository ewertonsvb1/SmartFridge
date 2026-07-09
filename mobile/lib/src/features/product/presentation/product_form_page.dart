import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfridge_mobile/src/core/network/api_error.dart';
import 'package:smartfridge_mobile/src/features/dashboard/presentation/dashboard_controller.dart';
import 'package:smartfridge_mobile/src/features/product/data/product_repository.dart';
import 'package:smartfridge_mobile/src/features/product/presentation/barcode_scanner_page.dart';
import 'package:smartfridge_mobile/src/features/product/presentation/product_controller.dart';

typedef BarcodeScannerLauncher = Future<String?> Function(BuildContext context);

final barcodeScannerLauncherProvider = Provider<BarcodeScannerLauncher>((ref) {
  return (context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerPage(),
        fullscreenDialog: true,
      ),
    );
  };
});

class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.initialProduct});

  final ProductModel? initialProduct;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  static const _minimumSearchLength = 2;
  static const _debounceDuration = Duration(milliseconds: 300);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoryController = TextEditingController();
  final _defaultUnitController = TextEditingController();
  final _defaultQuantityController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _manuController = TextEditingController();
  final _expController = TextEditingController();

  bool _loading = false;
  bool _searchingCatalog = false;
  bool _searchingBarcode = false;
  bool _showNoResults = false;
  bool _showBarcodeNotFound = false;

  Timer? _nameDebounceTimer;

  int _searchRequestId = 0;
  int _barcodeSearchRequestId = 0;
  int _catalogDetailRequestId = 0;

  List<CatalogProductSuggestionModel> _suggestions = const [];
  String _lastQueriedText = '';
  String? _barcodeValue;

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

  Future<void> _scanBarcode() async {
    if (_isEditing || _searchingBarcode) {
      return;
    }

    final barcode = await ref.read(barcodeScannerLauncherProvider)(context);
    if (!mounted || barcode == null) {
      return;
    }

    final normalizedBarcode = barcode.replaceAll(RegExp(r'\s+'), '');
    if (normalizedBarcode.isEmpty) {
      return;
    }

    setState(() {
      _barcodeValue = normalizedBarcode;
      _showBarcodeNotFound = false;
    });

    await _searchBarcode(normalizedBarcode);
  }

  Future<void> _searchBarcode(String barcode) async {
    final requestId = ++_barcodeSearchRequestId;

    setState(() {
      _searchingBarcode = true;
      _barcodeValue = barcode;
    });

    try {
      final suggestion = await ref
          .read(productRepositoryProvider)
          .findCatalogByBarcode(barcode);
      if (!mounted || requestId != _barcodeSearchRequestId) {
        return;
      }

      setState(() {
        _searchingBarcode = false;
        _showBarcodeNotFound = suggestion == null && barcode == _barcodeValue;
        if (suggestion != null) {
          _suggestions = const [];
          _showNoResults = false;
          _lastQueriedText = suggestion.name;
        }
      });

      if (suggestion != null) {
        await _applyCatalogSuggestion(suggestion);
      }
    } catch (_) {
      if (!mounted || requestId != _barcodeSearchRequestId) {
        return;
      }

      setState(() {
        _searchingBarcode = false;
        _showBarcodeNotFound = false;
      });
    }
  }

  void _onNameChanged(String rawValue) {
    if (_isEditing) {
      return;
    }

    _nameDebounceTimer?.cancel();
    final query = rawValue.trim();

    if (query.length < _minimumSearchLength) {
      setState(() {
        _searchingCatalog = false;
        _showNoResults = false;
        _lastQueriedText = '';
        _suggestions = const [];
      });
      return;
    }

    _nameDebounceTimer = Timer(_debounceDuration, () {
      _searchCatalog(query);
    });
  }

  Future<void> _searchCatalog(String query) async {
    final requestId = ++_searchRequestId;

    setState(() {
      _searchingCatalog = true;
      _lastQueriedText = query;
    });

    try {
      final suggestions =
          await ref.read(productRepositoryProvider).searchCatalog(query);
      if (!mounted || requestId != _searchRequestId) {
        return;
      }

      setState(() {
        _searchingCatalog = false;
        _suggestions = suggestions;
        _showNoResults =
            suggestions.isEmpty && query == _nameController.text.trim();
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) {
        return;
      }

      setState(() {
        _searchingCatalog = false;
        _suggestions = const [];
        _showNoResults = false;
      });
    }
  }

  void _selectSuggestion(CatalogProductSuggestionModel suggestion) {
    _nameDebounceTimer?.cancel();
    setState(() {
      _suggestions = const [];
      _showNoResults = false;
      _searchingCatalog = false;
      _lastQueriedText = suggestion.name;
    });
    unawaited(_applyCatalogSuggestion(suggestion));
  }

  Future<void> _applyCatalogSuggestion(
    CatalogProductSuggestionModel suggestion,
  ) async {
    _nameController.text = suggestion.name;
    _nameController.selection = TextSelection.fromPosition(
      TextPosition(offset: _nameController.text.length),
    );

    final requestId = ++_catalogDetailRequestId;

    try {
      final detail = await ref
          .read(productRepositoryProvider)
          .getCatalogById(suggestion.id);
      if (!mounted || requestId != _catalogDetailRequestId) {
        return;
      }

      _brandController.text = detail.brand ?? '';
      _categoryController.text = detail.category ?? '';
      _defaultUnitController.text = detail.defaultUnit ?? '';
      _defaultQuantityController.text =
          detail.defaultQuantity?.toString() ?? '';

      final detailBarcode = detail.barcode?.trim();
      if ((detailBarcode ?? '').isNotEmpty && (_barcodeValue ?? '').isEmpty) {
        _barcodeValue = detailBarcode;
      }

      setState(() {});
    } catch (_) {
      if (!mounted || requestId != _catalogDetailRequestId) {
        return;
      }
    }
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
    _nameDebounceTimer?.cancel();
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _defaultUnitController.dispose();
    _defaultQuantityController.dispose();
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
            if (!_isEditing) ...[
              FilledButton.icon(
                key: const ValueKey('product-barcode-scan-button'),
                onPressed: _loading || _searchingBarcode ? null : _scanBarcode,
                icon: _searchingBarcode
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Ler codigo de barras'),
              ),
              if ((_barcodeValue ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Codigo lido: $_barcodeValue',
                  key: const ValueKey('product-scanned-barcode-label'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (_showBarcodeNotFound && (_barcodeValue ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD7DCE2)),
                  ),
                  child: const Text(
                    'Codigo de barras nao encontrado.\nCadastrar novo produto?',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OU',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              key: const ValueKey('product-name-field'),
              controller: _nameController,
              onChanged: _onNameChanged,
              decoration: InputDecoration(
                labelText: 'Nome',
                suffixIcon: _searchingCatalog
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome';
                }
                return null;
              },
            ),
            if (!_isEditing &&
                _nameController.text.trim().length >= _minimumSearchLength &&
                _suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD7DCE2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _suggestions
                      .map(
                        (suggestion) => ListTile(
                          key: ValueKey('catalog-suggestion-${suggestion.id}'),
                          dense: true,
                          title: Text(suggestion.name),
                          onTap: () => _selectSuggestion(suggestion),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            if (!_isEditing &&
                _showNoResults &&
                _lastQueriedText == _nameController.text.trim()) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD7DCE2)),
                ),
                child: const Text(
                  'Nenhum produto encontrado.\nDeseja cadastrar um novo produto?',
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (!_isEditing) ...[
              TextFormField(
                key: const ValueKey('product-brand-field'),
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Marca'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('product-category-field'),
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('product-default-unit-field'),
                controller: _defaultUnitController,
                decoration: const InputDecoration(labelText: 'Unidade padrao'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('product-default-quantity-field'),
                controller: _defaultQuantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade padrao',
                ),
                validator: (value) {
                  final trimmed = (value ?? '').trim();
                  if (trimmed.isEmpty) {
                    return null;
                  }

                  final parsed = int.tryParse(trimmed);
                  if (parsed == null || parsed <= 0) {
                    return 'Quantidade padrao deve ser maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              key: const ValueKey('product-quantity-field'),
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
              key: const ValueKey('product-manufacture-field'),
              controller: _manuController,
              readOnly: true,
              onTap: () => _pickDate(_manuController),
              decoration: InputDecoration(
                labelText: 'Fabricacao (yyyy-mm-dd)',
                hintText: 'Selecione no calendario',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month_outlined),
                  onPressed: () => _pickDate(_manuController),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe a data de fabricacao';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('product-expiration-field'),
              controller: _expController,
              readOnly: true,
              onTap: () => _pickDate(_expController),
              decoration: InputDecoration(
                labelText: 'Validade (yyyy-mm-dd)',
                hintText: 'Selecione no calendario',
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
                                'Datas invalidas. Use o seletor de data.',
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      if (expirationDate.isBefore(manufactureDate)) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Validade nao pode ser antes da fabricacao.',
                              ),
                            ),
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
                            brand: _brandController.text.trim().isEmpty
                                ? null
                                : _brandController.text.trim(),
                            category: _categoryController.text.trim().isEmpty
                                ? null
                                : _categoryController.text.trim(),
                            defaultUnit:
                                _defaultUnitController.text.trim().isEmpty
                                    ? null
                                    : _defaultUnitController.text.trim(),
                            defaultQuantity:
                                _defaultQuantityController.text.trim().isEmpty
                                    ? null
                                    : int.parse(
                                        _defaultQuantityController.text.trim(),
                                      ),
                            barcode: (_barcodeValue ?? '').trim().isEmpty
                                ? null
                                : _barcodeValue!.trim(),
                          );
                        }

                        ref.invalidate(productListProvider);
                        ref.invalidate(dashboardProvider);
                        ref.invalidate(expiredProductsProvider);
                        ref.invalidate(nearExpirationProductsProvider);
                        ref.invalidate(globalDashboardProvider);

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
                        if (mounted) {
                          setState(() => _loading = false);
                        }
                      }
                    },
              child: _loading
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
