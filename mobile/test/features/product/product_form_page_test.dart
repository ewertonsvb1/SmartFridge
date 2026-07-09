import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfridge_mobile/src/features/product/data/product_repository.dart';
import 'package:smartfridge_mobile/src/features/product/presentation/product_form_page.dart';

void main() {
  testWidgets('ProductFormPage should not search before two characters',
      (WidgetTester tester) async {
    final repository = _FakeProductRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ProductFormPage()),
      ),
    );

    expect(find.byKey(const ValueKey('product-barcode-field')), findsNothing);
    expect(find.byKey(const ValueKey('product-barcode-scan-button')),
        findsOneWidget);
    expect(find.text('OU'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('product-name-field')),
      'L',
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.searchQueries, isEmpty);
  });

  testWidgets('ProductFormPage should debounce catalog search',
      (WidgetTester tester) async {
    final repository = _FakeProductRepository()
      ..searchResults['Lei'] = [
        CatalogProductSuggestionModel(id: 1, name: 'Leite Italac'),
      ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ProductFormPage()),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('product-name-field')),
      'Le',
    );
    await tester.pump(const Duration(milliseconds: 150));

    await tester.enterText(
      find.byKey(const ValueKey('product-name-field')),
      'Lei',
    );
    await tester.pump(const Duration(milliseconds: 299));

    expect(repository.searchQueries, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(repository.searchQueries, ['Lei']);
    expect(find.text('Leite Italac'), findsOneWidget);
  });

  testWidgets(
      'ProductFormPage should fill catalog metadata when selecting a suggestion',
      (WidgetTester tester) async {
    final repository = _FakeProductRepository()
      ..searchResults['Lei'] = [
        CatalogProductSuggestionModel(id: 1, name: 'Leite Italac'),
      ]
      ..catalogDetails[1] = CatalogProductDetailModel(
        id: 1,
        name: 'Leite Italac',
        brand: 'Italac',
        category: 'Laticinios',
        defaultUnit: 'L',
        defaultQuantity: 1,
        barcode: '7896004400912',
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ProductFormPage()),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('product-name-field')),
      'Lei',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('catalog-suggestion-1')));
    await tester.pump();
    await tester.pump();

    final nameField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('product-name-field')),
    );
    final brandField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('product-brand-field')),
    );
    final categoryField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('product-category-field')),
    );
    final defaultUnitField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('product-default-unit-field')),
    );
    final defaultQuantityField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('product-default-quantity-field')),
    );
    final quantityField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('product-quantity-field')),
    );
    expect(nameField.controller!.text, 'Leite Italac');
    expect(brandField.controller!.text, 'Italac');
    expect(categoryField.controller!.text, 'Laticinios');
    expect(defaultUnitField.controller!.text, 'L');
    expect(defaultQuantityField.controller!.text, '1');
    expect(quantityField.controller!.text, '1');
    expect(find.text('Leite Italac'), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-suggestion-1')), findsNothing);
  });

  testWidgets('ProductFormPage should allow manual edits after autofill',
      (WidgetTester tester) async {
    final repository = _FakeProductRepository()
      ..searchResults['Lei'] = [
        CatalogProductSuggestionModel(id: 1, name: 'Leite Italac'),
      ]
      ..catalogDetails[1] = CatalogProductDetailModel(
        id: 1,
        name: 'Leite Italac',
        brand: 'Italac',
        category: 'Laticinios',
        defaultUnit: 'L',
        defaultQuantity: 1,
        barcode: '7896004400912',
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ProductFormPage()),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('product-name-field')),
      'Lei',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('catalog-suggestion-1')));
    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('product-brand-field')),
      'Italac Zero Lactose',
    );
    await tester.enterText(
      find.byKey(const ValueKey('product-default-quantity-field')),
      '2',
    );
    await tester.pump();

    final brandField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('product-brand-field')),
    );
    final defaultQuantityField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('product-default-quantity-field')),
    );

    expect(brandField.controller!.text, 'Italac Zero Lactose');
    expect(defaultQuantityField.controller!.text, '2');
  });

  testWidgets('ProductFormPage should show no results message for new products',
      (WidgetTester tester) async {
    final repository = _FakeProductRepository()..searchResults['Ar'] = [];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ProductFormPage()),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('product-name-field')),
      'Ar',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.textContaining('Nenhum produto encontrado'), findsOneWidget);
    expect(
      find.textContaining('Deseja cadastrar um novo produto?'),
      findsOneWidget,
    );
  });

  testWidgets(
      'ProductFormPage should fill catalog metadata when barcode is found',
      (WidgetTester tester) async {
    final repository = _FakeProductRepository()
      ..barcodeResults['7896004400912'] =
          CatalogProductSuggestionModel(id: 2, name: 'Leite Italac Integral')
      ..catalogDetails[2] = CatalogProductDetailModel(
        id: 2,
        name: 'Leite Italac Integral',
        brand: 'Italac',
        category: 'Laticinios',
        defaultUnit: 'L',
        defaultQuantity: 1,
        barcode: '7896004400912',
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
          barcodeScannerLauncherProvider.overrideWithValue(
            (_) => Future.value('7896004400912'),
          ),
        ],
        child: const MaterialApp(home: ProductFormPage()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('product-barcode-scan-button')));
    await tester.pump();
    await tester.pump();

    final nameField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('product-name-field')),
    );
    final brandField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('product-brand-field')),
    );
    final quantityField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('product-quantity-field')),
    );

    expect(repository.barcodeQueries, ['7896004400912']);
    expect(nameField.controller!.text, 'Leite Italac Integral');
    expect(brandField.controller!.text, 'Italac');
    expect(quantityField.controller!.text, '1');
    expect(find.textContaining('Codigo lido: 7896004400912'), findsOneWidget);
  });

  testWidgets('ProductFormPage should show message when barcode is not found',
      (WidgetTester tester) async {
    final repository = _FakeProductRepository()
      ..barcodeResults['7896004400912'] = null;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
          barcodeScannerLauncherProvider.overrideWithValue(
            (_) => Future.value('7896004400912'),
          ),
        ],
        child: const MaterialApp(home: ProductFormPage()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('product-barcode-scan-button')));
    await tester.pump();

    expect(
        find.textContaining('Codigo de barras nao encontrado'), findsOneWidget);
    expect(find.textContaining('Cadastrar novo produto?'), findsOneWidget);
  });

  testWidgets(
      'ProductFormPage should ignore scanner cancellation without querying backend',
      (WidgetTester tester) async {
    final repository = _FakeProductRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
          barcodeScannerLauncherProvider.overrideWithValue(
            (_) => Future.value(null),
          ),
        ],
        child: const MaterialApp(home: ProductFormPage()),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('product-name-field')),
      'Leite Manual',
    );

    await tester.tap(find.byKey(const ValueKey('product-barcode-scan-button')));
    await tester.pump();

    final nameField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('product-name-field')),
    );

    expect(repository.barcodeQueries, isEmpty);
    expect(nameField.controller!.text, 'Leite Manual');
    expect(find.byKey(const ValueKey('product-scanned-barcode-label')),
        findsNothing);
    expect(
        find.textContaining('Codigo de barras nao encontrado'), findsNothing);
  });

  testWidgets(
      'ProductFormPage should preserve scanned barcode when catalog does not find it',
      (WidgetTester tester) async {
    final repository = _FakeProductRepository()
      ..barcodeResults['7896004400912'] = null;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
          barcodeScannerLauncherProvider.overrideWithValue(
            (_) => Future.value('7896004400912'),
          ),
        ],
        child: const MaterialApp(home: ProductFormPage()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('product-barcode-scan-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('product-name-field')),
      'Leite Novo',
    );
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('product-quantity-field')),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.enterText(
      find.byKey(const ValueKey('product-quantity-field')),
      '2',
    );

    await tester.dragUntilVisible(
      find.byKey(const ValueKey('product-manufacture-field')),
      find.byType(ListView),
      const Offset(0, -250),
    );
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('product-expiration-field')),
      find.byType(ListView),
      const Offset(0, -250),
    );

    tester
        .widget<TextFormField>(
          find.byKey(const ValueKey('product-manufacture-field')),
        )
        .controller!
        .text = '2026-07-01';
    tester
        .widget<TextFormField>(
          find.byKey(const ValueKey('product-expiration-field')),
        )
        .controller!
        .text = '2026-08-01';
    await tester.pump();

    await tester.tap(find.text('Salvar'));
    await tester.pump();

    expect(repository.createdPayloads, hasLength(1));
    expect(repository.createdPayloads.single['barcode'], '7896004400912');
  });

  testWidgets('ProductFormPage should submit catalog metadata on create',
      (WidgetTester tester) async {
    final repository = _FakeProductRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ProductFormPage()),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('product-name-field')),
      'Leite Italac',
    );
    await tester.enterText(
      find.byKey(const ValueKey('product-brand-field')),
      'Italac',
    );
    await tester.enterText(
      find.byKey(const ValueKey('product-category-field')),
      'Laticinios',
    );
    await tester.enterText(
      find.byKey(const ValueKey('product-default-unit-field')),
      'L',
    );
    await tester.enterText(
      find.byKey(const ValueKey('product-default-quantity-field')),
      '1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('product-quantity-field')),
      '2',
    );

    await tester.dragUntilVisible(
      find.byKey(const ValueKey('product-manufacture-field')),
      find.byType(ListView),
      const Offset(0, -250),
    );
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('product-expiration-field')),
      find.byType(ListView),
      const Offset(0, -250),
    );

    tester
        .widget<TextFormField>(
          find.byKey(const ValueKey('product-manufacture-field')),
        )
        .controller!
        .text = '2026-07-01';
    tester
        .widget<TextFormField>(
          find.byKey(const ValueKey('product-expiration-field')),
        )
        .controller!
        .text = '2026-08-01';
    await tester.pump();

    await tester.tap(find.text('Salvar'));
    await tester.pump();

    expect(repository.createdPayloads, hasLength(1));
    expect(repository.createdPayloads.single['name'], 'Leite Italac');
    expect(repository.createdPayloads.single['brand'], 'Italac');
    expect(repository.createdPayloads.single['category'], 'Laticinios');
    expect(repository.createdPayloads.single['defaultUnit'], 'L');
    expect(repository.createdPayloads.single['defaultQuantity'], 1);
    expect(repository.createdPayloads.single['barcode'], isNull);
  });
}

class _FakeProductRepository extends ProductRepository {
  _FakeProductRepository() : super(Dio());

  final List<String> searchQueries = [];
  final List<String> barcodeQueries = [];
  final Map<String, List<CatalogProductSuggestionModel>> searchResults = {};
  final Map<String, CatalogProductSuggestionModel?> barcodeResults = {};
  final Map<int, CatalogProductDetailModel> catalogDetails = {};
  final List<Map<String, dynamic>> createdPayloads = [];

  @override
  Future<List<CatalogProductSuggestionModel>> searchCatalog(
      String query) async {
    searchQueries.add(query);
    return searchResults[query] ?? const [];
  }

  @override
  Future<CatalogProductSuggestionModel?> findCatalogByBarcode(
      String barcode) async {
    barcodeQueries.add(barcode);
    return barcodeResults[barcode];
  }

  @override
  Future<CatalogProductDetailModel> getCatalogById(int id) async {
    return catalogDetails[id]!;
  }

  @override
  Future<void> create({
    required String name,
    required int quantity,
    required String manufactureDate,
    required String expirationDate,
    String? brand,
    String? category,
    String? defaultUnit,
    int? defaultQuantity,
    String? barcode,
  }) async {
    createdPayloads.add({
      'name': name,
      'quantity': quantity,
      'manufactureDate': manufactureDate,
      'expirationDate': expirationDate,
      'brand': brand,
      'category': category,
      'defaultUnit': defaultUnit,
      'defaultQuantity': defaultQuantity,
      'barcode': barcode,
    });
  }
}
