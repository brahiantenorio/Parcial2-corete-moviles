import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/dashboard_screen.dart';
import '../screens/productos_list_screen.dart';
import '../screens/producto_detail_screen.dart';
import '../screens/producto_form_screen.dart';
import '../widgets/main_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Configuración declarativa de rutas mediante go_router
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // ShellRoute que envuelve las pantallas principales con el MainScaffold (menú inferior y drawer)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/productos',
          name: 'productos',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProductosListScreen(),
          ),
        ),
      ],
    ),

    // Pantalla para registrar nuevo producto (POST)
    GoRoute(
      path: '/productos/nuevo',
      name: 'nuevo-producto',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProductoFormScreen(),
    ),

    // Pantalla para consultar detalle completo de un producto (GET /api/productos/{id})
    GoRoute(
      path: '/productos/:id',
      name: 'detalle-producto',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final idStr = state.pathParameters['id'];
        final id = int.tryParse(idStr ?? '') ?? 0;
        return ProductoDetailScreen(productoId: id);
      },
      routes: [
        // Sub-ruta para editar el producto existente (PUT /api/productos/{id})
        GoRoute(
          path: 'editar',
          name: 'editar-producto',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final idStr = state.pathParameters['id'];
            final id = int.tryParse(idStr ?? '') ?? 0;
            return ProductoFormScreen(productoId: id);
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Página No Encontrada')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Ruta no encontrada: ${state.uri}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Volver al Inicio'),
          ),
        ],
      ),
    ),
  ),
);
