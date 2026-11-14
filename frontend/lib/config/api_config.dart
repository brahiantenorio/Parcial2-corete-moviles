import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración centralizada de la API REST mediante flutter_dotenv
class ApiConfig {
  static const String defaultLocalUrl = 'http://127.0.0.1:8000/api';
  static const String defaultAndroidEmulatorUrl = 'http://10.0.2.2:8000/api';

  /// Obtiene la URL base ajustada según la plataforma de ejecución
  static String get baseUrl {
    String url = dotenv.env['API_BASE_URL'] ?? defaultLocalUrl;

    // Si se ejecuta en un emulador de Android (no web), 127.0.0.1 debe apuntar al host 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (url.contains('127.0.0.1') || url.contains('localhost')) {
        url = url.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2');
      }
    }

    return url;
  }

  // Endpoints de Autenticación
  static String get login => '$baseUrl/auth/login';
  static String get authMe => '$baseUrl/auth/me';
  static String get authVerify => '$baseUrl/auth/verify';

  // Endpoints del Inventario (Protegidos con JWT)
  static String get productos => '$baseUrl/productos';
  static String productoById(int id) => '$baseUrl/productos/$id';
  static String get dashboard => '$baseUrl/dashboard';
}
