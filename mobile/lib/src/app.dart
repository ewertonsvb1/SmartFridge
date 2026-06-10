import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfridge_mobile/src/core/auth/auth_session.dart';
import 'package:smartfridge_mobile/src/features/agenda/data/agenda_repository.dart';
import 'package:smartfridge_mobile/src/features/agenda/presentation/agenda_form_page.dart';
import 'package:smartfridge_mobile/src/features/agenda/presentation/agenda_page.dart';
import 'package:smartfridge_mobile/src/features/auth/presentation/login_page.dart';
import 'package:smartfridge_mobile/src/features/auth/presentation/register_page.dart';
import 'package:smartfridge_mobile/src/features/home/presentation/home_hub_page.dart';
import 'package:smartfridge_mobile/src/features/home/presentation/home_page.dart';
import 'package:smartfridge_mobile/src/features/house_bills/data/house_bills_repository.dart';
import 'package:smartfridge_mobile/src/features/house_bills/presentation/house_bill_form_page.dart';
import 'package:smartfridge_mobile/src/features/house_bills/presentation/house_bills_page.dart';
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
      GoRoute(path: '/home', builder: (_, __) => const HomeHubPage()),
      GoRoute(path: '/house-bills', builder: (_, __) => const HouseBillsPage()),
      GoRoute(
        path: '/house-bills/new',
        builder: (_, __) => const HouseBillFormPage(),
      ),
      GoRoute(
        path: '/house-bills/edit',
        builder: (_, state) {
          final bill = state.extra as HouseBillModel?;
          if (bill == null) {
            return const _InvalidHouseBillRoutePage();
          }
          return HouseBillFormPage(initialBill: bill);
        },
      ),
      GoRoute(path: '/agenda', builder: (_, __) => const AgendaPage()),
      GoRoute(
        path: '/agenda/new',
        builder: (_, state) =>
            AgendaFormPage(initialDate: state.extra as DateTime?),
      ),
      GoRoute(
        path: '/agenda/edit',
        builder: (_, state) {
          final event = state.extra as AgendaEventModel?;
          if (event == null) {
            return const _InvalidAgendaRoutePage();
          }
          return AgendaFormPage(initialEvent: event);
        },
      ),
      GoRoute(path: '/fridge', builder: (_, __) => const HomePage()),
      GoRoute(
          path: '/product/new', builder: (_, __) => const ProductFormPage()),
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

class _InvalidAgendaRoutePage extends StatelessWidget {
  const _InvalidAgendaRoutePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: const Center(
        child: Text('Evento invalido para edicao.'),
      ),
    );
  }
}

class _InvalidHouseBillRoutePage extends StatelessWidget {
  const _InvalidHouseBillRoutePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: const Center(
        child: Text('Conta invalida para edicao.'),
      ),
    );
  }
}

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

class SmartHouseApp extends ConsumerWidget {
  const SmartHouseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SmartHouse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7C7B)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
