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
    return content.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
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
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(dioProvider));
});
