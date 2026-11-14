import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_session.dart';

/// Servicio responsable del almacenamiento local y la persistencia de sesión:
/// - flutter_secure_storage: Almacena de forma encriptada y segura el token JWT (access_token).
/// - shared_preferences: Almacena información no sensible (nombre, correo, rol, estado de sesión).
class SessionStorageService {
  static const String _keyToken = 'jwt_access_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';
  static const String _keyIsLoggedIn = 'is_logged_in';

  final FlutterSecureStorage _secureStorage;

  SessionStorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  /// Guarda la sesión completa distribuyendo responsabilidades:
  /// Token sensible -> flutter_secure_storage
  /// Datos informativos -> shared_preferences
  Future<void> saveSession({
    required String token,
    required UserSession user,
  }) async {
    // 1. Guardar token de manera segura
    await _secureStorage.write(key: _keyToken, value: token);

    // 2. Guardar datos no sensibles en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, user.id);
    await prefs.setString(_keyUserName, user.nombre);
    await prefs.setString(_keyUserEmail, user.email);
    await prefs.setString(_keyUserRole, user.rol);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  /// Obtiene el token JWT almacenado de forma segura
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _keyToken);
    } catch (_) {
      return null;
    }
  }

  /// Recupera los datos del usuario desde SharedPreferences y opcionalmente adjunta el token seguro
  Future<UserSession?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final token = await getToken();

    if (!isLoggedIn || token == null || token.isEmpty) {
      return null;
    }

    final id = prefs.getInt(_keyUserId) ?? 0;
    final nombre = prefs.getString(_keyUserName) ?? 'Usuario';
    final email = prefs.getString(_keyUserEmail) ?? '';
    final rol = prefs.getString(_keyUserRole) ?? 'usuario';

    return UserSession(
      id: id,
      nombre: nombre,
      email: email,
      rol: rol,
      token: token,
    );
  }

  /// Verifica si existe un token almacenado y el flag de sesión activa
  Future<bool> hasActiveSession() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Elimina por completo los datos locales de autenticación (logout)
  Future<void> clearSession() async {
    // 1. Eliminar token de flutter_secure_storage
    try {
      await _secureStorage.delete(key: _keyToken);
    } catch (_) {}

    // 2. Limpiar datos de SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserRole);
    await prefs.setBool(_keyIsLoggedIn, false);
  }
}
