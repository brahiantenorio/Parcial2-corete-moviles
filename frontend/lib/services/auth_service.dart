import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/user_session.dart';

/// Servicio responsable de las operaciones de autenticación con la API REST utilizando Dio
class AuthService {
  final Dio _dio;

  AuthService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  /// Realiza el inicio de sesión enviando credenciales a POST /api/auth/login
  /// Retorna un mapa con 'token' y 'user' (UserSession) si la autenticación es exitosa
  Future<({String token, UserSession user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final userData = data['user'] as Map<String, dynamic>;
        final user = UserSession.fromJson(userData, token: token);
        return (token: token, user: user);
      }

      throw 'Respuesta inesperada del servidor de autenticación.';
    } on DioException catch (e) {
      throw _handleDioError(e, 'iniciar sesión');
    } catch (e) {
      throw 'Error inesperado al iniciar sesión: $e';
    }
  }

  /// Verifica la validez de un token JWT consultando GET /api/auth/verify
  Future<UserSession?> verifyToken(String token) async {
    try {
      final response = await _dio.get(
        ApiConfig.authVerify,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['user'] is Map<String, dynamic>) {
          return UserSession.fromJson(data['user'] as Map<String, dynamic>, token: token);
        }
      }
      return null;
    } on DioException catch (_) {
      // Si el servidor responde 401 o falla, el token no es válido o expiró
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Traduce las excepciones de Dio a mensajes claros en español
  String _handleDioError(DioException e, String accion) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tiempo de espera agotado al $accion en ${ApiConfig.baseUrl}. Verifique su conexión y que el servidor backend esté activo.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar con el servidor (${ApiConfig.baseUrl}). Verifique que el backend FastAPI esté ejecutándose en el puerto 8000.';
    }

    if (e.response != null) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      String? serverDetail;
      if (data is Map && data.containsKey('detail')) {
        if (data['detail'] is String) {
          serverDetail = data['detail'];
        } else if (data['detail'] is List) {
          final list = data['detail'] as List;
          serverDetail = list.map((item) => item['msg'] ?? item.toString()).join(', ');
        }
      }

      if (serverDetail != null && serverDetail.isNotEmpty) {
        return serverDetail;
      }

      switch (status) {
        case 400:
          return 'Petición inválida: Verifique los datos ingresados.';
        case 401:
          return 'Credenciales incorrectas: Correo electrónico o contraseña no válidos.';
        case 403:
          return 'Acceso denegado: Su cuenta no tiene permisos o está inactiva.';
        case 404:
          return 'El servicio de autenticación no fue encontrado en el servidor.';
        case 422:
          return 'Formato de datos no válido: Verifique el formato del correo y contraseña.';
        case 500:
          return 'Error interno del servidor al procesar la autenticación.';
        default:
          return 'El servidor respondió con código $status al $accion.';
      }
    }

    return 'Error de comunicación al $accion: ${e.message}';
  }
}
