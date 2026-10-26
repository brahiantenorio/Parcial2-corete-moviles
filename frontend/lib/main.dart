import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'providers/inventario_provider.dart';
import 'services/producto_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga de variables de entorno mediante flutter_dotenv
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("[ENV] Variables de entorno cargadas exitosamente.");
  } catch (e) {
    debugPrint("[ENV] Advertencia: No se encontró o no se pudo cargar archivo .env: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => InventarioProvider(service: ProductoService())..inicializar(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Sistema de Gestión de Inventario',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
