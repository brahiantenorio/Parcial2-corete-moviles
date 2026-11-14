import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_session.dart';

void main() {
  group('Pruebas Unitarias de Autenticación y Modelos JWT', () {
    test('Debe deserializar correctamente un mapa JSON a UserSession', () {
      final json = {
        'id': 1,
        'nombre': 'Brahian Andres Tenorio',
        'email': 'brahian.tenorio@uceva.edu.co',
        'rol': 'admin',
      };
      const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummyPayload.dummySignature12345';

      final user = UserSession.fromJson(json, token: testToken);

      expect(user.id, 1);
      expect(user.nombre, 'Brahian Andres Tenorio');
      expect(user.email, 'brahian.tenorio@uceva.edu.co');
      expect(user.rol, 'admin');
      expect(user.token, testToken);
    });

    test('Debe generar un tokenPreview seguro enmascarando el contenido sensible', () {
      const fullToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIn0.s3cr3tS1gn4tur3Pr0t3ct10n';
      const user = UserSession(
        id: 1,
        nombre: 'Brahian',
        email: 'brahian@uceva.edu.co',
        rol: 'admin',
        token: fullToken,
      );

      final preview = user.tokenPreview;

      // El preview debe comenzar con los primeros 15 caracteres del token
      expect(preview.startsWith(fullToken.substring(0, 15)), isTrue);
      // Debe contener puntos suspensivos en el centro
      expect(preview.contains('...'), isTrue);
      // El preview nunca debe ser idéntico al token completo
      expect(preview, isNot(equals(fullToken)));
      // Debe terminar con los últimos 8 caracteres
      expect(preview.endsWith(fullToken.substring(fullToken.length - 8)), isTrue);
    });

    test('Debe serializar UserSession a JSON omitiendo datos de token', () {
      const user = UserSession(
        id: 2,
        nombre: 'Docente Evaluador',
        email: 'profesor@uceva.edu.co',
        rol: 'docente',
        token: 'token_secreto_no_debe_ir_en_json',
      );

      final map = user.toJson();

      expect(map['id'], 2);
      expect(map['nombre'], 'Docente Evaluador');
      expect(map['email'], 'profesor@uceva.edu.co');
      expect(map['rol'], 'docente');
      expect(map.containsKey('token'), isFalse);
    });
  });
}
