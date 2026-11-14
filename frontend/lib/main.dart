import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/inventario_provider.dart';
import 'services/auth_service.dart';
import 'services/producto_service.dart';
import 'services/session_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga de variables de entorno mediante flutter_dotenv
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("[ENV] Variables de entorno cargadas exitosamente.");
  } catch (e) {
    debugPrint("[ENV] Advertencia: No se encontró o no se pudo cargar archivo .env: $e");
  }

  // Servicios de persistencia segura y autenticación
  final sessionStorage = SessionStorageService();
  final authService = AuthService();
  final authProvider = AuthProvider(
    authService: authService,
    sessionStorage: sessionStorage,
  );

  // Inicializar persistencia de sesión antes de renderizar
  await authProvider.inicializar();

  // Servicio de productos protegido con inyección automática de JWT
  final productoService = ProductoService(
    sessionStorage: sessionStorage,
    onUnauthorized: () {
      authProvider.logout();
    },
  );

  final inventarioProvider = InventarioProvider(service: productoService);
  if (authProvider.isAuthenticated) {
    inventarioProvider.inicializar();
  }

  final router = createAppRouter(authProvider);

  runApp(MyApp(
    authProvider: authProvider,
    inventarioProvider: inventarioProvider,
    router: router,
  ));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  final InventarioProvider inventarioProvider;
  final GoRouter router;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.inventarioProvider,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<InventarioProvider>.value(value: inventarioProvider),
      ],
      child: MaterialApp.router(
        title: 'Sistema de Gestión de Inventario',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }
}
