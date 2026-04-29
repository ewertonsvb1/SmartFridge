import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/core/network/api_client.dart';

class ShoppingItem {
  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.checked,
  });

  final int id;
  final String name;
  final int quantity;
  final bool checked;

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as int,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      checked: json['checked'] as bool,
    );
  }
}

class ShoppingRepository {
  ShoppingRepository(this._dio);
  final Dio _dio;

  Future<List<ShoppingItem>> list() async {
    final response = await _dio.get('/shopping-list');
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create(String name, int quantity) async {
    await _dio.post('/shopping-list', data: {'name': name, 'quantity': quantity});
  }

  Future<void> update(ShoppingItem item) async {
    await _dio.put('/shopping-list/${item.id}', data: {
      'name': item.name,
      'quantity': item.quantity,
      'checked': item.checked,
    });
  }

  Future<void> delete(int id) async {
    await _dio.delete('/shopping-list/$id');
  }
}

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(ref.watch(dioProvider));
});
