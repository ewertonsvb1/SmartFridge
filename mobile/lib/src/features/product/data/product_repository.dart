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

class NfceImportPreviewItemModel {
  NfceImportPreviewItemModel({
    required this.lineNumber,
    required this.description,
    required this.quantity,
    required this.suggestedManufactureDate,
    required this.suggestedExpirationDate,
    required this.suggestedShelfLifeDays,
    required this.shelfLifeRuleCode,
    required this.manualReviewRequired,
  });

  final int lineNumber;
  final num quantity;
  final String description;
  final String? suggestedManufactureDate;
  final String? suggestedExpirationDate;
  final int? suggestedShelfLifeDays;
  final String? shelfLifeRuleCode;
  final bool manualReviewRequired;

  factory NfceImportPreviewItemModel.fromJson(Map<String, dynamic> json) {
    return NfceImportPreviewItemModel(
      lineNumber: json['lineNumber'] as int,
      description: json['description'] as String,
      quantity: json['quantity'] as num,
      suggestedManufactureDate: json['suggestedManufactureDate'] as String?,
      suggestedExpirationDate: json['suggestedExpirationDate'] as String?,
      suggestedShelfLifeDays: json['suggestedShelfLifeDays'] as int?,
      shelfLifeRuleCode: json['shelfLifeRuleCode'] as String?,
      manualReviewRequired: json['manualReviewRequired'] as bool? ?? false,
    );
  }
}

class NfceImportPreviewModel {
  NfceImportPreviewModel({
    required this.sourceUrl,
    required this.accessKey,
    required this.noteNumber,
    required this.emissionDate,
    required this.items,
  });

  final String sourceUrl;
  final String? accessKey;
  final String? noteNumber;
  final String emissionDate;
  final List<NfceImportPreviewItemModel> items;

  factory NfceImportPreviewModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? <dynamic>[]);
    return NfceImportPreviewModel(
      sourceUrl: json['sourceUrl'] as String? ?? '',
      accessKey: json['accessKey'] as String?,
      noteNumber: json['noteNumber'] as String?,
      emissionDate: json['emissionDate'] as String,
      items: rawItems
          .map((item) =>
              NfceImportPreviewItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class NfceImportConfirmItemInput {
  NfceImportConfirmItemInput({
    required this.name,
    required this.quantity,
    required this.manufactureDate,
    required this.expirationDate,
  });

  final String name;
  final int quantity;
  final String manufactureDate;
  final String expirationDate;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'manufactureDate': manufactureDate,
      'expirationDate': expirationDate,
    };
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
  }) async {
    await _dio.post('/products', data: {
      'name': name,
      'quantity': quantity,
      'manufactureDate': manufactureDate,
      'expirationDate': expirationDate,
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

  Future<NfceImportPreviewModel> previewNfceImport(String qrCodePayload) async {
    final response = await _dio.post('/products/nfce/preview', data: {
      'qrCodePayload': qrCodePayload,
    });

    return NfceImportPreviewModel.fromJson(
      Map<String, dynamic>.from(response.data as Map<String, dynamic>),
    );
  }

  Future<List<ProductModel>> confirmNfceImport(
    List<NfceImportConfirmItemInput> items,
  ) async {
    final response = await _dio.post('/products/nfce/confirm', data: {
      'items': items.map((item) => item.toJson()).toList(),
    });

    final data =
        Map<String, dynamic>.from(response.data as Map<String, dynamic>);
    final rawProducts = (data['products'] as List<dynamic>? ?? <dynamic>[]);
    return rawProducts
        .map(
            (product) => ProductModel.fromJson(product as Map<String, dynamic>))
        .toList();
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(dioProvider));
});
