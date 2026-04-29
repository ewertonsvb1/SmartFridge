import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/features/product/data/product_repository.dart';

final productListProvider = FutureProvider<List<ProductModel>>((ref) async {
  return ref.watch(productRepositoryProvider).list();
});

final expiredProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  return ref.watch(productRepositoryProvider).list(status: 'EXPIRED');
});

final nearExpirationProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  return ref.watch(productRepositoryProvider).list(status: 'NEAR_EXPIRATION');
});

final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(productRepositoryProvider).dashboard();
});
