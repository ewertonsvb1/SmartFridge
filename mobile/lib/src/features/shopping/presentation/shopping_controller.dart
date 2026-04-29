import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/features/shopping/data/shopping_repository.dart';

final shoppingListProvider = FutureProvider<List<ShoppingItem>>((ref) async {
  return ref.watch(shoppingRepositoryProvider).list();
});
