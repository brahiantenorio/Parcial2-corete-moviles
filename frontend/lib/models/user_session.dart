/// Modelo que representa la sesión del usuario autenticado
class UserSession {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final String? token;

  const UserSession({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.token,
  });

  factory UserSession.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserSession(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String? ?? 'usuario',
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
    };
  }

  /// Retorna un preview enmascarado del token JWT para visualización segura (ej. eyJhbGciOi...8fcf6eb)
  String get tokenPreview {
    if (token == null || token!.isEmpty) return 'No disponible';
    if (token!.length <= 20) return '***';
    return '${token!.substring(0, 15)}...${token!.substring(token!.length - 8)}';
  }

  UserSession copyWith({
    int? id,
    String? nombre,
    String? email,
    String? rol,
    String? token,
  }) {
    return UserSession(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      token: token ?? this.token,
    );
  }
}
