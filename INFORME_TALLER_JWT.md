# INFORME TÉCNICO — TALLER: IMPLEMENTACIÓN DE AUTENTICACIÓN JWT Y PROTECCIÓN DE SERVICIOS EN FLUTTER

**Asignatura:** Electiva Profesional I — Desarrollo de Aplicaciones Móviles  
**Docente:** Electiva Profesional I  
**Estudiante:** Brahian Andres Tenorio  
**Institución:** Universidad Central del Valle del Cauca (UCEVA)  
**Repositorio Oficial:** [github.com/brahiantenorio/Parcial2-corete-moviles](https://github.com/brahiantenorio/Parcial2-corete-moviles)  
**Flujo GitFlow:** Rama base `dev` | Rama de trabajo `feature/taller_jwt` | Integración hacia `main`  

---

## 1. Resumen Ejecutivo del Taller

En el marco del taller práctico de la asignatura **Electiva Profesional I**, se implementó un sistema completo de **Autenticación mediante JSON Web Tokens (JWT)** y **Protección estricta de servicios CRUD y Dashboard**, integrando la aplicación móvil desarrollada en **Flutter** con el backend RESTful en **FastAPI + SQLite** originario del Parcial 2.

### Aspectos Clave de la Solución:
1. **Seguridad Robusta en Backend:**
   - Creación de tabla `usuarios` en SQLite con persistencia real.
   - Almacenamiento seguro de contraseñas mediante hashing **PBKDF2-HMAC-SHA256 con salt aleatorio de 16 bytes** e iteraciones criptográficas (100.000 rounds).
   - Generación de tokens **JWT estándar (RFC 7519)** firmados mediante algoritmo **HS256** con clave secreta de 256 bits y tiempo de expiración (24 horas).
   - Protección estricta de todos los endpoints de consulta, registro, edición y eliminación (CRUD) y estadísticas del Dashboard con la dependencia `Depends(get_current_user)`.
   - Rechazo riguroso de peticiones sin token o con token alterado/expirado mediante código HTTP **401 Unauthorized** con encabezado `WWW-Authenticate: Bearer`.

2. **Seguridad y Persistencia en Frontend (Flutter):**
   - **Separación de Responsabilidades en Almacenamiento Local:**
     - `flutter_secure_storage`: Almacena el `access_token` JWT cifrado en el llavero seguro nativo del sistema operativo (Keystore en Android / Keychain en iOS / DPAPI en Windows).
     - `shared_preferences`: Almacena exclusivamente datos informativos no sensibles (nombre, correo, rol y bandera de sesión).
   - **Consumo HTTP Avanzado con Dio:**
     - Implementación de `InterceptorsWrapper` que intercepta todas las peticiones salientes e inyecta de forma transparente el encabezado `Authorization: Bearer <token>`.
     - Captura reactiva de respuestas **401 Unauthorized** para revocar la sesión local automáticamente y proteger al usuario ante tokens expirados.
   - **Control de Navegación y Guardianes de Acceso:**
     - Enrutamiento declarativo con `go_router` integrando un **Navigation Guard (redirect)** que impide el acceso a rutas protegidas (`/`, `/productos`, `/productos/nuevo`, `/productos/:id`, `/sesion`) a usuarios no autenticados, forzando la redirección inmediata a `/login`.
     - Sincronización reactiva con `refreshListenable: authProvider`.
   - **Interfaz de Usuario (Material 3):**
     - Pantalla de inicio de sesión (`LoginScreen`) con validaciones de formulario, alternancia de visibilidad de contraseña, estados de carga e indicadores de prueba rápida para evaluación.
     - Pantalla dedicada de Información de Sesión (`SessionInfoScreen`) que cumple con el Requisito 2.5 mostrando nombre, correo, rol, estado activo, indicador seguro y enmascarado del token (`tokenPreview`), y botón de cierre de sesión con diálogo de confirmación.

---

## 2. Usuarios de Prueba Disponibles

Para facilitar la evaluación y verificación inmediata tanto en la aplicación Flutter como mediante herramientas como Swagger UI o cURL, la base de datos se inicializa automáticamente con 3 usuarios sembrados:

| Nombre | Correo Electrónico (`email`) | Contraseña (`password`) | Rol | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| **Brahian Andres Tenorio** | `brahian.tenorio@uceva.edu.co` | `admin123` | `admin` | Administrador del sistema |
| **Docente Evaluador** | `profesor@uceva.edu.co` | `profe2026` | `docente` | Cuenta para evaluación docente |
| **Usuario de Prueba** | `usuario@test.com` | `123456` | `usuario` | Cuenta estándar de pruebas |

---

## 3. Arquitectura del Backend (FastAPI + SQLite)

### 3.1. Esquema de la Tabla `usuarios` en SQLite (`backend/database.py`)

```sql
CREATE TABLE IF NOT EXISTS usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    rol TEXT DEFAULT 'admin',
    activo INTEGER DEFAULT 1
);
```

### 3.2. Endpoints Implementados en el Backend (`backend/main.py`)

| Método | Endpoint | Nivel de Acceso | Descripción | Respuestas HTTP |
| :--- | :--- | :---: | :--- | :--- |
| `GET` | `/` | Público | Información general de la API y rutas | `200 OK` |
| `POST` | `/api/auth/login` | Público | Valida credenciales y genera token JWT | `200 OK`, `401 Unauthorized`, `403 Forbidden` |
| `GET` | `/api/auth/me` | **Protegido (JWT)** | Retorna datos del usuario en sesión | `200 OK`, `401 Unauthorized` |
| `GET` | `/api/auth/verify` | **Protegido (JWT)** | Valida si el token local sigue activo | `200 OK`, `401 Unauthorized` |
| `GET` | `/api/dashboard` | **Protegido (JWT)** | Métricas consolidadas del inventario | `200 OK`, `401 Unauthorized` |
| `GET` | `/api/productos` | **Protegido (JWT)** | Listar productos con filtros | `200 OK`, `401 Unauthorized` |
| `GET` | `/api/productos/{id}` | **Protegido (JWT)** | Detalle técnico de un producto | `200 OK`, `401`, `404 Not Found` |
| `POST` | `/api/productos` | **Protegido (JWT)** | Crear un producto nuevo en BD | `201 Created`, `400`, `401 Unauthorized` |
| `PUT` | `/api/productos/{id}` | **Protegido (JWT)** | Actualizar producto existente | `200 OK`, `400`, `401`, `404 Not Found` |
| `DELETE` | `/api/productos/{id}` | **Protegido (JWT)** | Eliminar producto por ID | `200 OK`, `401`, `404 Not Found` |

---

## 4. Arquitectura del Frontend (Flutter)

### 4.1. Estructura de Capas
```text
frontend/lib/
├── config/
│   ├── api_config.dart          # Configuración y resolución de IPs según plataforma
│   ├── app_router.dart          # go_router con guardianes de autenticación y redirección
│   └── app_theme.dart           # Tema Material 3 adaptativo
├── models/
│   ├── producto.dart            # Entidad Producto
│   ├── dashboard_stats.dart     # Métricas consolidadas
│   └── user_session.dart        # Entidad de usuario autenticado y tokenPreview
├── services/
│   ├── auth_service.dart        # Cliente Dio para /api/auth/login y /api/auth/verify
│   ├── producto_service.dart    # Cliente Dio con Interceptor para Bearer token y captura 401
│   └── session_storage_service.dart # Persistencia en flutter_secure_storage + shared_preferences
├── providers/
│   ├── auth_provider.dart       # Gestión del ciclo de vida de la sesión (Login/Logout/Validación)
│   └── inventario_provider.dart # Estado global de productos y métricas
├── screens/
│   ├── login_screen.dart        # Formulario de inicio de sesión y chips de credenciales
│   ├── session_info_screen.dart # Vista requerida 2.5: Datos de usuario, indicador de token y logout
│   ├── dashboard_screen.dart    # Dashboard con métricas protegidas
│   ├── productos_list_screen.dart # Catálogo de inventario protegido
│   ├── producto_detail_screen.dart # Detalle técnico de producto
│   └── producto_form_screen.dart # Formulario crear / editar producto
└── widgets/
    └── main_scaffold.dart       # Menú lateral Drawer y barra inferior con estado de usuario
```

---

## 5. Matriz de Cumplimiento de Pruebas Obligatorias (Sección 3)

| # | Escenario Obligatorio | Resultado Obtenido | Evidencia Técnica |
| :-: | :--- | :---: | :--- |
| **1** | **Acceso sin autenticación** | **CUMPLIDO** | Al abrir la app sin sesión previa, el guardián de `go_router` intercepta la navegación y redirige automáticamente a `/login`. Peticiones directas a la API sin token devuelven `401 Unauthorized`. |
| **2** | **Credenciales incorrectas** | **CUMPLIDO** | Al ingresar contraseña o correo erróneo, la API devuelve `401 Unauthorized` con el mensaje: *"Credenciales incorrectas: Correo electrónico o contraseña no válidos."*. Flutter muestra banner de alerta en rojo. |
| **3** | **Inicio de sesión correcto** | **CUMPLIDO** | Credenciales válidas generan un token JWT válido (HS256), almacenado en `flutter_secure_storage`, y redirige inmediatamente al Dashboard principal mostrando notificación de bienvenida. |
| **4** | **Consumo de servicios protegidos** | **CUMPLIDO** | Todas las operaciones CRUD (listar, crear, actualizar, eliminar) y Dashboard envían automáticamente el encabezado `Authorization: Bearer <token>` mediante el interceptor Dio, respondiendo `200 OK` y `201 Created`. |
| **5** | **Persistencia de sesión** | **CUMPLIDO** | Al reiniciar o recargar la aplicación, `SessionStorageService` recupera el token de `flutter_secure_storage` y los datos del usuario de `shared_preferences`, verificando con `/api/auth/verify` y manteniendo la sesión activa sin solicitar login de nuevo. |
| **6** | **Validación desde backend** | **CUMPLIDO** | Se ejecutó la suite automatizada `backend/test_jwt_auth.py` realizando peticiones directas sin token y con tokens alterados; todos los intentos fueron rechazados por FastAPI con `401 Unauthorized`. |
| **7** | **Cierre de sesión (Logout)** | **CUMPLIDO** | Al presionar el botón de cerrar sesión en la vista de sesión o en el Drawer, se eliminan el token seguro y los datos de preferencias, notificando a `go_router` para redirigir inmediatamente a `/login`. |

---

## 6. Resultados de las Pruebas Automatizadas

### 6.1. Suite Automatizada del Backend (`backend/test_jwt_auth.py`)
```text
======================================================================
INICIANDO PRUEBAS DEL TALLER: AUTENTICACIÓN JWT Y PROTECCIÓN DE SERVICIOS
======================================================================
[DATABASE] Tabla usuarios lista: 3 usuarios registrados.
[DATABASE] Base de datos lista. 12 productos registrados.

[ESCENARIO 1] Intentando acceder a servicios protegidos sin token...
 -> GET /api/productos: Código 401 - Acceso Denegado (Correcto)
 -> Detalle del error: Acceso no autorizado: No se proporcionó el token de autenticación en el encabezado Authorization.
 -> GET /api/dashboard: Código 401 - Acceso Denegado (Correcto)

[ESCENARIO 2] Intentando iniciar sesión con credenciales inválidas...
 -> POST /api/auth/login (Clave incorrecta): Código 401
 -> Detalle: Credenciales incorrectas: Correo electrónico o contraseña no válidos.
 -> POST /api/auth/login (Usuario inexistente): Código 401

[ESCENARIO 3] Petición con token Bearer alterado / no válido...
 -> Código 401 - Detalle: Token de autenticación inválido o alterado.

[ESCENARIO 4] Iniciando sesión con credenciales válidas...
 -> Login Exitoso para: Brahian Andres Tenorio (brahian.tenorio@uceva.edu.co)
 -> Token JWT Generado: eyJhbGciOiJIUzI1NiIsInR5c... (Longitud: 280 caracteres)

[ESCENARIO 5] Verificando token JWT y perfil de usuario autenticado...
 -> GET /api/auth/verify: {'autenticado': True, 'user': {'id': 1, 'nombre': 'Brahian Andres Tenorio', 'email': 'brahian.tenorio@uceva.edu.co', 'rol': 'admin'}, 'mensaje': 'Sesión activa y token JWT válido.'}
 -> GET /api/auth/me: {'id': 1, 'nombre': 'Brahian Andres Tenorio', 'email': 'brahian.tenorio@uceva.edu.co', 'rol': 'admin'}

[ESCENARIO 6] Consumo de operaciones protegidas (CRUD + Dashboard)...
 -> GET /api/dashboard: {'total_productos': 12, 'total_unidades': 194, 'valor_total_inventario': 154120000.0}
 -> GET /api/productos: 12 productos listados con token
 -> POST /api/productos: Producto #14 creado con éxito
 -> PUT /api/productos/14: Producto actualizado (Precio: 240000.0)
 -> DELETE /api/productos/14: Producto 'Teclado Ergonomico Bluetooth Test' con ID 14 eliminado exitosamente.

======================================================================
¡TODAS LAS PRUEBAS OBLIGATORIAS PASARON CON ÉXITO AL 100%!
======================================================================
```

### 6.2. Pruebas Unitarias de Flutter (`flutter test`)
```text
00:00 +0: D:/.../frontend/test/auth_test.dart: Pruebas Unitarias de Autenticación y Modelos JWT Debe deserializar correctamente un mapa JSON a UserSession
00:00 +1: D:/.../frontend/test/auth_test.dart: Pruebas Unitarias de Autenticación y Modelos JWT Debe generar un tokenPreview seguro enmascarando el contenido sensible
00:00 +2: D:/.../frontend/test/auth_test.dart: Pruebas Unitarias de Autenticación y Modelos JWT Debe serializar UserSession a JSON omitiendo datos de token
00:01 +3: D:/.../frontend/test/producto_model_test.dart: Pruebas Unitarias del Modelo Producto Debe deserializar correctamente un mapa JSON a Producto
00:01 +4: D:/.../frontend/test/producto_model_test.dart: Pruebas Unitarias del Modelo Producto Debe serializar un Producto a JSON correctamente para POST
00:01 +5: D:/.../frontend/test/producto_model_test.dart: Pruebas Unitarias de DashboardStats Debe calcular las métricas consolidando una lista de productos
00:01 +6: All tests passed!
```

---

## 7. Instrucciones para Ejecutar y Probar el Proyecto

### 7.1. Iniciar el Backend
```bash
cd backend
pip install -r requirements.txt
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```
- API activa en: `http://127.0.0.1:8000`
- Swagger UI interactivo: `http://127.0.0.1:8000/docs`

### 7.2. Ejecutar las Pruebas Automatizadas del Backend
```bash
cd backend
python test_jwt_auth.py
```

### 7.3. Iniciar la Aplicación Flutter
```bash
cd frontend
flutter pub get
flutter run -d chrome     # O flutter run -d windows / flutter run -d emulator
```

### 7.4. Ejecutar las Pruebas Unitarias de Flutter
```bash
cd frontend
flutter test
```
