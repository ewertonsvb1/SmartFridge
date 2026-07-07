import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/core/network/api_client.dart';

class ProductModel {
  ProductModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.manufactureDate,
    required this.expirationDate,
    required this.status,
  });

  final int id;
  final String name;
  final int quantity;
  final String manufactureDate;
  final String expirationDate;
  final String status;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      manufactureDate: json['manufactureDate'] as String,
      expirationDate: json['expirationDate'] as String,
      status: json['status'] as String,
    );
  }
}

class CatalogProductSuggestionModel {
  CatalogProductSuggestionModel({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory CatalogProductSuggestionModel.fromJson(Map<String, dynamic> json) {
    return CatalogProductSuggestionModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class CatalogProductDetailModel {
  CatalogProductDetailModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.defaultUnit,
    required this.defaultQuantity,
    required this.barcode,
  });

  final int id;
  final String name;
  final String? brand;
  final String? category;
  final String? defaultUnit;
  final int? defaultQuantity;
  final String? barcode;

  factory CatalogProductDetailModel.fromJson(Map<String, dynamic> json) {
    return CatalogProductDetailModel(
      id: json['id'] as int,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      category: json['category'] as String?,
      defaultUnit: json['defaultUnit'] as String?,
      defaultQuantity: json['defaultQuantity'] as int?,
      barcode: json['barcode'] as String?,
    );
  }
}

class ProductRepository {
  ProductRepository(this._dio);
  final Dio _dio;

  Future<List<ProductModel>> list({String? status}) async {
    final response = await _dio.get('/products', queryParameters: {
      if (status != null) 'status': status,
      'size': 50,
      'sort': 'createdAt,desc',
    });
    final content = (response.data['content'] as List<dynamic>?) ?? <dynamic>[];
    return content
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> dashboard() async {
    final response = await _dio.get('/products/dashboard');
    return Map<String, dynamic>.from(response.data as Map<String, dynamic>);
  }

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
    await _dio.post('/products', data: {
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

  Future<void> update({
    required int id,
    required String name,
    required int quantity,
    required String manufactureDate,
    required String expirationDate,
  }) async {
    await _dio.put('/products/$id', data: {
      'name': name,
      'quantity': quantity,
      'manufactureDate': manufactureDate,
      'expirationDate': expirationDate,
    });
  }

  Future<void> delete(int id) async {
    await _dio.delete('/products/$id');
  }

  Future<List<CatalogProductSuggestionModel>> searchCatalog(String query) async {
    final response = await _dio.get(
      '/products/catalog/search',
      queryParameters: {'q': query},
    );
    final data = response.data as List<dynamic>? ?? <dynamic>[];
    return data
        .map(
          (item) => CatalogProductSuggestionModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<CatalogProductSuggestionModel?> findCatalogByBarcode(String barcode) async {
    try {
      final response = await _dio.get('/products/catalog/barcode/$barcode');
      return CatalogProductSuggestionModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (exception) {
      if (exception.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<CatalogProductDetailModel> getCatalogById(int id) async {
    final response = await _dio.get('/products/catalog/$id');
    return CatalogProductDetailModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(dioProvider));
});
