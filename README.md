# Sistema de Gestión de Inventario — API REST + Flutter (JWT & Servicios Protegidos)

**Electiva Profesional I — Desarrollo de Aplicaciones Móviles**  
**Taller:** Implementación de autenticación JWT y protección de servicios en Flutter (Continuación Parcial 2)  
**Estudiante:** Brahian Andres Tenorio  
**Universidad:** Universidad Central del Valle del Cauca (UCEVA)  
**Repositorio Oficial:** [https://github.com/brahiantenorio/Parcial2-corete-moviles](https://github.com/brahiantenorio/Parcial2-corete-moviles)  
**Ramas GitFlow:** `main` | `dev` | `feature/taller_jwt`  

---

## 1. Descripción General

Solución informática integral para la administración, control y seguridad de inventarios de productos en establecimientos comerciales. La plataforma consta de dos componentes completamente desacoplados, sincronizados y protegidos de extremo a extremo mediante **JSON Web Tokens (JWT)**:

1. **Backend RESTful:** Desarrollado con **Python + FastAPI**, conectado a una base de datos relacional **SQLite** con persistencia real (no se pierden los datos al reiniciar el servidor), documentación interactiva Swagger/OpenAPI, soporte CORS y middleware de autenticación con verificación de tokens JWT y hashing de contraseñas.
2. **Frontend Móvil y Multiplataforma:** Desarrollado en **Flutter**, implementando arquitectura limpia por capas (Modelos, Servicios, Proveedores de Estado, Vistas y Widgets), navegación declarativa con guardianes de acceso en `go_router`, consumo HTTP robusto mediante `dio` con interceptores de Bearer token y captura de códigos 401, y almacenamiento híbrido seguro con `flutter_secure_storage` y `shared_preferences`.

---

## 2. Tecnologías Utilizadas

### Backend
* **Lenguaje:** Python 3.14+
* **Framework Web:** FastAPI 0.162+
* **Servidor ASGI:** Uvicorn 0.54+
* **Autenticación y Seguridad:** PyJWT 2.15+ (Algoritmo HS256, RFC 7519)
* **Criptografía de Contraseñas:** PBKDF2-HMAC-SHA256 con Salt aleatorio de 16 bytes e iteraciones
* **Persistencia / Base de Datos:** SQLite3 (Motor relacional embebido ACID)
* **Validación de Datos:** Pydantic 2.14+
* **Documentación Automática:** Swagger UI (`/docs`) y ReDoc (`/redoc`)

### Frontend (Flutter)
* **Framework:** Flutter 3.47+ (Dart 3.13+)
* **Consumo HTTP:** `dio: ^5.11.1` (con interceptores para `Authorization: Bearer <token>` y manejo de 401)
* **Almacenamiento Seguro del Token:** `flutter_secure_storage: ^9.2.4` (Almacenamiento cifrado en Keychain/Keystore)
* **Almacenamiento Local No Sensible:** `shared_preferences: ^2.5.6` (Datos de usuario y sesión activa)
* **Navegación & Guardianes de Acceso:** `go_router: ^18.1.1` (Rutas declarativas, ShellRoute y guardia `redirect`)
* **Variables de Entorno:** `flutter_dotenv: ^6.0.1` (gestión de URL base en `.env`)
* **Gestión de Estado:** `provider: ^6.1.5` (separación limpia entre UI y lógica de negocio)
* **Formateo Numérico / Moneda:** `intl: ^0.20.3` (moneda colombiana y separadores)
* **Diseño:** Material 3 con tema personalizado adaptativo

---

## 3. Estructura del Repositorio

```text
Parcial2-corete-moviles/
│
├── backend/                             # Proyecto Backend API REST
│   ├── database.py                      # Conexión SQLite, tablas 'productos' y 'usuarios' con semilla
│   ├── auth.py                          # Lógica de seguridad: hashing, creación y verificación JWT
│   ├── models.py                        # Modelos Pydantic (Productos, Auth, Login, Tokens)
│   ├── main.py                          # Endpoints de Login y servicios CRUD protegidos
│   ├── test_jwt_auth.py                 # Suite de pruebas automatizadas obligatorias (6 escenarios)
│   ├── requirements.txt                 # Dependencias Python (FastAPI, Uvicorn, PyJWT, Pydantic)
│   ├── run_backend.bat                  # Script de inicio rápido del Backend
│   └── inventario.db                    # Base de datos relacional SQLite
│
├── frontend/                            # Aplicación Móvil en Flutter
│   ├── .env                             # Variables de entorno locales (URL de API)
│   ├── .env.example                     # Plantilla de variables de entorno
│   ├── pubspec.yaml                     # Dependencias y recursos de Flutter
│   ├── lib/
│   │   ├── config/
│   │   │   ├── api_config.dart          # Configuración y resolución automática de IP/Host
│   │   │   ├── app_router.dart          # go_router con guardián de autenticación (redirect)
│   │   │   └── app_theme.dart           # Tema Material 3
│   │   ├── models/
│   │   │   ├── producto.dart            # Entidad Producto (fromJson, toJson, cálculos)
│   │   │   ├── dashboard_stats.dart     # Métricas consolidadas del inventario
│   │   │   └── user_session.dart        # Entidad de usuario autenticado y tokenPreview
│   │   ├── services/
│   │   │   ├── auth_service.dart        # Consumo de /api/auth/login y verify con Dio
│   │   │   ├── producto_service.dart    # Cliente Dio con Interceptor para Bearer token
│   │   │   └── session_storage_service.dart # Persistencia con flutter_secure_storage y shared_preferences
│   │   ├── providers/
│   │   │   ├── auth_provider.dart       # Estado de autenticación reactivo y persistente
│   │   │   └── inventario_provider.dart # Estado global reactivo (CRUD y filtros)
│   │   ├── screens/
│   │   │   ├── login_screen.dart        # Pantalla de Login con validación y chips de prueba
│   │   │   ├── session_info_screen.dart # Vista 2.5: Nombre, correo, estado, token preview y logout
│   │   │   ├── dashboard_screen.dart    # Dashboard con tarjetas métricas en tiempo real
│   │   │   ├── productos_list_screen.dart # Catálogo, búsqueda, filtro y acciones
│   │   │   ├── producto_detail_screen.dart # Consulta y detalle completo de producto
│   │   │   └── producto_form_screen.dart # Formulario Registrar / Editar con validación
│   │   ├── widgets/
│   │   │   ├── stat_card.dart           # Tarjeta de estadísticas con gradientes
│   │   │   ├── producto_card.dart       # Ítem visual de lista con badge de stock
│   │   │   ├── empty_state.dart         # Estados de carga, vacío y error
│   │   │   └── main_scaffold.dart       # Barra inferior y menú Drawer con info de usuario
│   │   └── main.dart                    # Inicialización y punto de entrada de la aplicación
│   └── test/
│       ├── auth_test.dart               # Pruebas unitarias de modelos de sesión y tokenPreview
│       └── producto_model_test.dart     # Pruebas unitarias de modelos y cálculos
│
├── INFORME_TALLER_JWT.md                # Informe técnico detallado del taller y evidencias
├── run_backend.bat                      # Acceso directo para ejecutar Backend
├── run_frontend.bat                     # Acceso directo para ejecutar Frontend
├── .gitignore                           # Exclusión de temporales y compilados
└── README.md                            # Documentación técnica completa
```

---

## 4. Usuarios de Prueba Disponibles

Al arrancar por primera vez, el backend siembra automáticamente 3 cuentas de usuario en la base de datos relacional SQLite:

| Nombre | Correo Electrónico (`email`) | Contraseña (`password`) | Rol |
| :--- | :--- | :--- | :--- |
| **Brahian Andres Tenorio** | `brahian.tenorio@uceva.edu.co` | `admin123` | `admin` |
| **Docente Evaluador** | `profesor@uceva.edu.co` | `profe2026` | `docente` |
| **Usuario de Prueba** | `usuario@test.com` | `123456` | `usuario` |

---

## 5. Endpoints de la API REST

### 5.1. Endpoints Públicos y de Autenticación
| Método | Endpoint | Funcionalidad | Respuestas HTTP |
| :--- | :--- | :--- | :--- |
| `GET` | `/` | Información general de la API | `200 OK` |
| `POST` | `/api/auth/login` | Iniciar sesión y generar token JWT | `200 OK`, `401 Unauthorized`, `403 Forbidden` |
| `GET` | `/api/auth/me` | Consultar perfil del usuario autenticado | `200 OK`, `401 Unauthorized` |
| `GET` | `/api/auth/verify` | Verificar si el token JWT actual es válido | `200 OK`, `401 Unauthorized` |

### 5.2. Endpoints Protegidos con JWT (`Authorization: Bearer <token>`)
| Método | Endpoint | Funcionalidad | Respuestas HTTP |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/dashboard` | Métricas consolidadas del inventario | `200 OK`, `401 Unauthorized` |
| `GET` | `/api/productos` | Listar productos con filtros opcionales | `200 OK`, `401 Unauthorized` |
| `GET` | `/api/productos/{id}` | Detalle de un producto específico | `200 OK`, `401`, `404 Not Found` |
| `POST` | `/api/productos` | Registrar nuevo producto con código único | `201 Created`, `400`, `401 Unauthorized` |
| `PUT` | `/api/productos/{id}` | Actualizar un producto existente | `200 OK`, `400`, `401`, `404 Not Found` |
| `DELETE` | `/api/productos/{id}` | Eliminar un producto por su ID | `200 OK`, `401`, `404 Not Found` |

---

## 6. Seguridad y Manejo de Sesión en Flutter

### 6.1. Almacenamiento Local Híbrido
- **`flutter_secure_storage`:** Almacena de manera cifrada el `access_token` JWT. Nunca se guarda en texto plano ni se expone completo en pantalla.
- **`shared_preferences`:** Almacena datos informativos del perfil (`user_name`, `user_email`, `user_role`, `is_logged_in`).

### 6.2. Inyección Automática de Token y Manejo de Expiración (Dio Interceptors)
El servicio `ProductoService` implementa un interceptor que:
1. Lee asíncronamente el token desde `SessionStorageService`.
2. Añade automáticamente `Authorization: Bearer <token>` a todas las peticiones a la API.
3. Si la respuesta del servidor es `401 Unauthorized`, notifica inmediatamente a `AuthProvider` para cerrar la sesión localmente y devolver al usuario a la pantalla de login.

### 6.3. Guardián de Rutas (Navigation Guard en `go_router`)
- Si un usuario no autenticado intenta navegar a cualquier ruta protegida (`/`, `/productos`, `/productos/nuevo`, `/productos/:id`, `/sesion`), `go_router` lo redirige a `/login`.
- Si un usuario autenticado intenta entrar a `/login`, es redirigido automáticamente al Dashboard.

### 6.4. Vista de Información de Sesión (`SessionInfoScreen`)
Cumple estrictamente con el **Requisito 2.5**:
- Muestra el nombre y correo del usuario autenticado.
- Indica el estado de autenticación: *Sesión Activa* (insignia verde).
- Muestra un indicador enmascarado del token JWT (`tokenPreview`, ej. `eyJhbGciOiJIUzI...fcf6eb722`) confirmando el cifrado en `flutter_secure_storage`.
- Dispone de un botón visible para Cerrar Sesión con modal de confirmación.

---

## 7. Instrucciones de Instalación y Ejecución

### 7.1. Iniciar el Backend (FastAPI + SQLite)
```bash
# 1. Navegar a la carpeta del backend
cd backend

# 2. Instalar dependencias
pip install -r requirements.txt

# 3. Iniciar el servidor
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```
- API activa en: `http://127.0.0.1:8000`
- Documentación Swagger UI interactiva: `http://127.0.0.1:8000/docs`

### 7.2. Ejecutar Pruebas Automatizadas del Backend
```bash
cd backend
python test_jwt_auth.py
```

### 7.3. Iniciar el Frontend (Flutter)
```bash
# 1. Navegar a la carpeta del frontend
cd frontend

# 2. Instalar paquetes de Flutter
flutter pub get

# 3. Ejecutar en el dispositivo deseado
flutter run -d chrome      # Web
flutter run -d windows     # Windows Desktop
flutter run -d emulator    # Emulador Android
```

### 7.4. Ejecutar Pruebas Unitarias de Flutter
```bash
cd frontend
flutter test
```

---

## 8. Cumplimiento de Pruebas Obligatorias (Sección 3)

| Escenario | Comportamiento Comprobado | Estado |
| :--- | :--- | :---: |
| **Acceso sin autenticación** | Flutter redirige a `/login`; peticiones directas sin token a endpoints protegidos responden `401 Unauthorized`. | **Superado** |
| **Credenciales incorrectas** | El backend responde `401` y Flutter despliega alerta de error con mensaje explicativo. | **Superado** |
| **Inicio de sesión correcto** | El backend valida credenciales, genera JWT y Flutter almacena el token en almacenamiento seguro, ingresando al Dashboard. | **Superado** |
| **Consumo de servicios protegidos** | Las operaciones CRUD y Dashboard se ejecutan exitosamente utilizando el encabezado `Authorization: Bearer <token>`. | **Superado** |
| **Persistencia de sesión** | Al recargar la aplicación, se recuperan las credenciales seguras y se conserva la sesión activa sin forzar login. | **Superado** |
| **Validación desde backend** | Suite `test_jwt_auth.py` comprueba que peticiones directas sin token o con token alterado son rechazadas con `401`. | **Superado** |
| **Cierre de sesión** | El botón de logout borra el token de `flutter_secure_storage`, limpia preferencias y redirige al login. | **Superado** |
