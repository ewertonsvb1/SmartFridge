import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfridge_mobile/src/core/auth/auth_session.dart';
import 'package:smartfridge_mobile/src/features/auth/presentation/login_page.dart';
import 'package:smartfridge_mobile/src/features/auth/presentation/register_page.dart';
import 'package:smartfridge_mobile/src/features/home/presentation/home_page.dart';
import 'package:smartfridge_mobile/src/features/product/data/product_repository.dart';
import 'package:smartfridge_mobile/src/features/product/presentation/product_form_page.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: session,
    redirect: (_, state) {
      final location = state.uri.path;
      final isAuthRoute = location == '/login' || location == '/register';

      if (!session.initialized) {
        return location == '/splash' ? null : '/splash';
      }

      if (!session.authenticated) {
        return isAuthRoute ? null : '/login';
      }

      if (location == '/splash' || isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const _SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(path: '/product/new', builder: (_, __) => const ProductFormPage()),
      GoRoute(
        path: '/product/edit',
        builder: (_, state) {
          final product = state.extra as ProductModel?;
          if (product == null) {
            return const _InvalidProductRoutePage();
          }
          return ProductFormPage(initialProduct: product);
        },
      ),
    ],
  );
});

class _InvalidProductRoutePage extends StatelessWidget {
  const _InvalidProductRoutePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: const Center(
        child: Text('Produto inválido para edição.'),
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class SmartFridgeApp extends ConsumerWidget {
  const SmartFridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SmartFridge',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7C7B)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
