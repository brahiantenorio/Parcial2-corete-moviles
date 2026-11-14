import 'package:flutter/foundation.dart';
import '../models/user_session.dart';
import '../services/auth_service.dart';
import '../services/session_storage_service.dart';

/// Provider responsable de la gestión del estado global de autenticación y sesión:
/// - Control de login, logout y persistencia
/// - Estado reactivo para la navegación declarativa (go_router)
/// - Exposición de datos del usuario autenticado e indicadores seguros de token
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SessionStorageService _sessionStorage;

  AuthProvider({
    AuthService? authService,
    SessionStorageService? sessionStorage,
  })  : _authService = authService ?? AuthService(),
        _sessionStorage = sessionStorage ?? SessionStorageService();

  bool _isAuthenticated = false;
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _errorMessage;
  UserSession? _currentUser;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserSession? get currentUser => _currentUser;
  String get tokenPreview => _currentUser?.tokenPreview ?? 'Sin token almacenado';

  /// Inicializa la sesión al arrancar la aplicación:
  /// Comprueba la existencia del token en flutter_secure_storage y los datos en SharedPreferences
  Future<void> inicializar() async {
    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedUser = await _sessionStorage.getUserSession();
      if (savedUser != null && savedUser.token != null && savedUser.token!.isNotEmpty) {
        // Token presente localmente: validar opcionalmente con el backend
        final verifiedUser = await _authService.verifyToken(savedUser.token!);
        if (verifiedUser != null) {
          _currentUser = verifiedUser;
          _isAuthenticated = true;
        } else {
          // Si el servidor confirma que el token expiró, limpiamos la sesión
          await _sessionStorage.clearSession();
          _currentUser = null;
          _isAuthenticated = false;
        }
      } else {
        _currentUser = null;
        _isAuthenticated = false;
      }
    } catch (e) {
      debugPrint('[AUTH] Error durante inicialización de sesión: $e');
      _currentUser = null;
      _isAuthenticated = false;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Ejecuta el proceso de inicio de sesión con Dio
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        email: email.trim(),
        password: password,
      );

      // Almacenar en flutter_secure_storage y shared_preferences
      await _sessionStorage.saveSession(
        token: result.token,
        user: result.user,
      );

      _currentUser = result.user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión activa: elimina las credenciales locales y notifica para redirigir al login
  Future<void> logout() async {
    await _sessionStorage.clearSession();
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpia mensajes de error de la pantalla
  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }
}
