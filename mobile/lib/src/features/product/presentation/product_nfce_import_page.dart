import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smartfridge_mobile/src/core/network/api_error.dart';
import 'package:smartfridge_mobile/src/features/dashboard/presentation/dashboard_controller.dart';
import 'package:smartfridge_mobile/src/features/product/data/product_repository.dart';
import 'package:smartfridge_mobile/src/features/product/presentation/product_controller.dart';

class ProductNfceImportPage extends ConsumerStatefulWidget {
  const ProductNfceImportPage({super.key});

  @override
  ConsumerState<ProductNfceImportPage> createState() =>
      _ProductNfceImportPageState();
}

class _ProductNfceImportPageState extends ConsumerState<ProductNfceImportPage> {
  final _payloadController = TextEditingController();
  bool _loadingPreview = false;
  bool _submitting = false;
  NfceImportPreviewModel? _preview;
  List<_EditableImportedItem> _items = const [];

  @override
  void dispose() {
    _payloadController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  String _formatDate(String raw) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _formatQuantity(num quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final initialDate = DateTime.tryParse(controller.text.trim()) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final month = picked.month.toString().padLeft(2, '0');
      final day = picked.day.toString().padLeft(2, '0');
      controller.text = '${picked.year}-$month-$day';
    }
  }

  Future<void> _loadPreview([String? payload]) async {
    final normalizedPayload = (payload ?? _payloadController.text).trim();
    if (normalizedPayload.isEmpty) {
      _showSnackBar('Informe ou escaneie o QR Code da NFC-e.');
      return;
    }

    setState(() => _loadingPreview = true);
    try {
      final preview = await ref
          .read(productRepositoryProvider)
          .previewNfceImport(normalizedPayload);

      final newItems = preview.items
          .map(
            (item) => _EditableImportedItem(
              name: item.description,
              quantity: _formatQuantity(item.quantity),
              manufactureDate:
                  item.suggestedManufactureDate ?? preview.emissionDate,
              expirationDate: item.suggestedExpirationDate ?? '',
              manualReviewRequired: item.manualReviewRequired,
              shelfLifeRuleCode: item.shelfLifeRuleCode,
            ),
          )
          .toList();

      for (final item in _items) {
        item.dispose();
      }

      setState(() {
        _preview = preview;
        _items = newItems;
      });
    } catch (e) {
      _showSnackBar(formatApiError(e));
    } finally {
      if (mounted) {
        setState(() => _loadingPreview = false);
      }
    }
  }

  Future<void> _openScanner() async {
    final scannedPayload = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _NfceScannerSheet(),
    );

    if (!mounted || scannedPayload == null || scannedPayload.trim().isEmpty) {
      return;
    }

    _payloadController.text = scannedPayload;
    await _loadPreview(scannedPayload);
  }

  Future<void> _confirmImport() async {
    final selectedItems = _items.where((item) => item.selected).toList();
    if (selectedItems.isEmpty) {
      _showSnackBar('Selecione pelo menos um item para importar.');
      return;
    }

    final confirmItems = <NfceImportConfirmItemInput>[];
    for (var index = 0; index < selectedItems.length; index++) {
      final item = selectedItems[index];
      final validationMessage = item.validationMessage(index + 1);
      if (validationMessage != null) {
        _showSnackBar(validationMessage);
        return;
      }

      final parsed = item.toConfirmInput();
      if (parsed == null) {
        return;
      }
      if (parsed.expirationDate.compareTo(parsed.manufactureDate) < 0) {
        _showSnackBar(
          'A validade do item ${index + 1} nao pode ser antes da fabricacao.',
        );
        return;
      }
      confirmItems.add(parsed);
    }

    setState(() => _submitting = true);
    try {
      await ref.read(productRepositoryProvider).confirmNfceImport(confirmItems);
      ref.invalidate(productListProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(expiredProductsProvider);
      ref.invalidate(nearExpirationProductsProvider);
      ref.invalidate(globalDashboardProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${confirmItems.length} produto(s) importado(s) com sucesso.',
          ),
        ),
      );
      context.pop(true);
    } catch (e) {
      _showSnackBar(formatApiError(e));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar NFC-e'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Voltar',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leia o QR Code da nota ou cole o link',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A pre-visualizacao nao salva nada. Voce revisa os itens antes de confirmar.',
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('nfce-payload-field'),
                  controller: _payloadController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Link ou payload do QR Code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: _loadingPreview ? null : _loadPreview,
                      icon: _loadingPreview
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search_rounded),
                      label: const Text('Buscar nota'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _loadingPreview ? null : _openScanner,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Abrir camera'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_preview != null) ...[
            const SizedBox(height: 24),
            _PreviewSummaryCard(
              noteNumber: _preview!.noteNumber,
              accessKey: _preview!.accessKey,
              sourceUrl: _preview!.sourceUrl,
              emissionDate: _formatDate(_preview!.emissionDate),
              itemCount: _items.length,
            ),
            const SizedBox(height: 16),
            const Text(
              'Revise os itens importados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...List.generate(_items.length, (index) {
              final item = _items[index];
              return _ImportedItemCard(
                index: index,
                item: item,
                onChanged: () => setState(() {}),
                onPickManufactureDate: () =>
                    _pickDate(item.manufactureController),
                onPickExpirationDate: () =>
                    _pickDate(item.expirationController),
              );
            }),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _submitting ? null : _confirmImport,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: const Text('Confirmar importacao'),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
}

class _PreviewSummaryCard extends StatelessWidget {
  const _PreviewSummaryCard({
    required this.noteNumber,
    required this.accessKey,
    required this.sourceUrl,
    required this.emissionDate,
    required this.itemCount,
  });

  final String? noteNumber;
  final String? accessKey;
  final String sourceUrl;
  final String emissionDate;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Text(
            'Nota ${noteNumber ?? 'sem numero'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('Emissao: $emissionDate'),
          Text('Itens encontrados: $itemCount'),
          if ((accessKey ?? '').isNotEmpty) Text('Chave: $accessKey'),
          const SizedBox(height: 8),
          Text(
            sourceUrl,
            style: const TextStyle(fontSize: 12, color: Color(0xFF66707C)),
          ),
        ],
      ),
    );
  }
}

class _ImportedItemCard extends StatelessWidget {
  const _ImportedItemCard({
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onPickManufactureDate,
    required this.onPickExpirationDate,
  });

  final int index;
  final _EditableImportedItem item;
  final VoidCallback onChanged;
  final VoidCallback onPickManufactureDate;
  final VoidCallback onPickExpirationDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: item.selected,
                onChanged: (value) {
                  item.selected = value ?? false;
                  onChanged();
                },
              ),
              Expanded(
                child: Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (item.manualReviewRequired)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECC8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Revisao manual',
                    style: TextStyle(
                      color: Color(0xFF9A6500),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: ValueKey('nfce-item-name-$index'),
            controller: item.nameController,
            decoration: const InputDecoration(labelText: 'Nome do produto'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: ValueKey('nfce-item-quantity-$index'),
            controller: item.quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantidade'),
          ),
          const SizedBox(height: 12),
          _DateInputField(
            keyValue: 'nfce-item-manufacture-$index',
            controller: item.manufactureController,
            label: 'Fabricacao',
            onTap: onPickManufactureDate,
          ),
          const SizedBox(height: 12),
          _DateInputField(
            keyValue: 'nfce-item-expiration-$index',
            controller: item.expirationController,
            label: 'Validade',
            onTap: onPickExpirationDate,
          ),
          if ((item.shelfLifeRuleCode ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Regra aplicada: ${item.shelfLifeRuleCode}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF65707C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateInputField extends StatelessWidget {
  const _DateInputField({
    required this.keyValue,
    required this.controller,
    required this.label,
    required this.onTap,
  });

  final String keyValue;
  final TextEditingController controller;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey(keyValue),
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: '$label (yyyy-mm-dd)',
        suffixIcon: IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.calendar_month_outlined),
        ),
      ),
    );
  }
}

class _EditableImportedItem {
  _EditableImportedItem({
    required String name,
    required String quantity,
    required String manufactureDate,
    required String expirationDate,
    required this.manualReviewRequired,
    required this.shelfLifeRuleCode,
  })  : nameController = TextEditingController(text: name),
        quantityController = TextEditingController(text: quantity),
        manufactureController = TextEditingController(text: manufactureDate),
        expirationController = TextEditingController(text: expirationDate);

  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController manufactureController;
  final TextEditingController expirationController;
  final bool manualReviewRequired;
  final String? shelfLifeRuleCode;
  bool selected = true;

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    manufactureController.dispose();
    expirationController.dispose();
  }

  String? validationMessage(int itemNumber) {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      return 'Informe o nome do item $itemNumber.';
    }

    final quantity = int.tryParse(quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      return 'Informe uma quantidade inteira valida para o item $itemNumber.';
    }

    final manufactureDate = manufactureController.text.trim();
    final expirationDate = expirationController.text.trim();
    if (DateTime.tryParse(manufactureDate) == null ||
        DateTime.tryParse(expirationDate) == null) {
      return 'Revise as datas do item $itemNumber antes de confirmar.';
    }

    return null;
  }

  NfceImportConfirmItemInput? toConfirmInput() {
    final name = nameController.text.trim();
    final quantity = int.tryParse(quantityController.text.trim());
    final manufactureDate = manufactureController.text.trim();
    final expirationDate = expirationController.text.trim();
    if (name.isEmpty ||
        quantity == null ||
        quantity <= 0 ||
        DateTime.tryParse(manufactureDate) == null ||
        DateTime.tryParse(expirationDate) == null) {
      return null;
    }

    return NfceImportConfirmItemInput(
      name: name,
      quantity: quantity,
      manufactureDate: manufactureDate,
      expirationDate: expirationDate,
    );
  }
}

class _NfceScannerSheet extends StatefulWidget {
  const _NfceScannerSheet();

  @override
  State<_NfceScannerSheet> createState() => _NfceScannerSheetState();
}

class _NfceScannerSheetState extends State<_NfceScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) {
      return;
    }

    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) {
      return;
    }

    _handled = true;
    Navigator.of(context).pop(rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Aponte a camera para o QR Code da NFC-e',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Fechar camera'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
