# Sistema de Gestión de Inventario — API REST + Flutter

**Electiva Profesional I — Desarrollo de Aplicaciones Móviles**  
**Segundo Parcial Práctico**  
**Estudiante:** Brahian Andres Tenorio  
**Universidad:** Universidad de Nariño / Electiva Profesional I  

---

## 1. Descripción General

Solución informática completa para la administración y control de inventarios de productos en establecimientos comerciales. La plataforma consta de dos componentes desacoplados y completamente funcionales:

1. **Backend RESTful:** Desarrollado con **Python + FastAPI**, conectado a una base de datos relacional **SQLite** con persistencia real (no se pierden los datos al reiniciar el servidor), documentación interactiva Swagger/OpenAPI y soporte CORS.
2. **Frontend Móvil y Multiplataforma:** Desarrollado en **Flutter**, implementando arquitectura limpia por capas (Modelos, Servicios, Proveedores de Estado, Vistas y Widgets), navegación declarativa con `go_router`, consumo HTTP robusto mediante `dio`, y configuración centralizada de variables de entorno mediante `flutter_dotenv`.

---

## 2. Tecnologías Utilizadas

### Backend
* **Lenguaje:** Python 3.14+
* **Framework Web:** FastAPI 0.162+
* **Servidor ASGI:** Uvicorn 0.54+
* **Persistencia / Base de Datos:** SQLite3 (Motor relacional embebido ACID)
* **Validación de Datos:** Pydantic 2.14+
* **Documentación Automática:** Swagger UI (`/docs`) y ReDoc (`/redoc`)

### Frontend (Flutter)
* **Framework:** Flutter 3.47+ (Dart 3.13+)
* **Consumo HTTP:** `dio: ^5.11.1` (con manejo estricto de excepciones y timeouts)
* **Navegación:** `go_router: ^18.1.1` (rutas declarativas y ShellRoute)
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
│   ├── database.py                      # Conexión SQLite y semilla de 10 productos iniciales
│   ├── models.py                        # Modelos Pydantic (Validaciones y Schemas)
│   ├── main.py                          # Endpoints CRUD, middleware CORS y ciclo de vida
│   ├── requirements.txt                 # Dependencias Python
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
│   │   │   ├── app_router.dart          # Navegación declarativa go_router
│   │   │   └── app_theme.dart           # Tema Material 3
│   │   ├── models/
│   │   │   ├── producto.dart            # Entidad Producto (fromJson, toJson, cálculos)
│   │   │   └── dashboard_stats.dart     # Métricas consolidadas del inventario
│   │   ├── services/
│   │   │   └── producto_service.dart    # Cliente HTTP Dio y traducción de errores
│   │   ├── providers/
│   │   │   └── inventario_provider.dart # Estado global reactivo (CRUD y filtros)
│   │   ├── screens/
│   │   │   ├── dashboard_screen.dart    # Dashboard con tarjetas métricas en tiempo real
│   │   │   ├── productos_list_screen.dart # Catálogo, búsqueda, filtro y acciones
│   │   │   ├── producto_detail_screen.dart # Consulta y detalle completo de producto
│   │   │   └── producto_form_screen.dart # Formulario Registrar / Editar con validación
│   │   ├── widgets/
│   │   │   ├── stat_card.dart           # Tarjeta de estadísticas con gradientes
│   │   │   ├── producto_card.dart       # Ítem visual de lista con badge de stock
│   │   │   ├── empty_state.dart         # Estados de carga, vacío y error
│   │   │   └── main_scaffold.dart       # Barra inferior y menú Drawer lateral
│   │   └── main.dart                    # Punto de entrada de la aplicación
│   └── test/
│       └── producto_model_test.dart     # Pruebas unitarias de modelos y cálculos
│
├── run_backend.bat                      # Acceso directo para ejecutar Backend
├── run_frontend.bat                     # Acceso directo para ejecutar Frontend
├── .gitignore                           # Exclusión de temporales y compilados
└── README.md                            # Documentación técnica completa
```

---

## 4. Base de Datos

La persistencia se realiza mediante **SQLite**, garantizando almacenamiento duradero sin requerir la instalación de motores pesados adicionales.

### 4.1. Esquema de la Tabla `productos`

| Campo | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Identificador numérico único autogenerado |
| `nombre` | TEXT | NOT NULL | Nombre comercial del producto |
| `codigo` | TEXT | NOT NULL UNIQUE | Código de inventario único (SKU) |
| `descripcion` | TEXT | NULL | Descripción técnica o complementaria (opcional) |
| `precio` | REAL | NOT NULL CHECK(precio > 0) | Precio unitario de venta |
| `cantidad` | INTEGER | NOT NULL CHECK(cantidad >= 0) | Unidades físicas disponibles en almacén |
| `categoria` | TEXT | NOT NULL | Clasificación o departamento del producto |

### 4.2. Datos de Prueba Iniciales (Semilla de 10 Productos)

Al arrancar por primera vez, el sistema detecta si la base de datos está vacía y siembra automáticamente 10 productos de prueba realistas:

1. **LP-001**: Laptop Lenovo ThinkPad T14 ($3.450.000 — 12 uds.) — Tecnología
2. **MS-002**: Mouse Inalámbrico Logitech MX Master 3 ($380.000 — 35 uds.) — Accesorios
3. **KB-003**: Teclado Mecánico Keychron K2 RGB ($420.000 — 20 uds.) — Accesorios
4. **MN-004**: Monitor Dell 27 4K UHD ($1.750.000 — 15 uds.) — Monitores
5. **AU-005**: Auriculares Sony WH-1000XM5 ($1.450.000 — 10 uds.) — Audio
6. **IMP-006**: Impresora Multifuncional Epson EcoTank L3250 ($890.000 — 8 uds.) — Oficina
7. **SSD-007**: Disco Sólido SSD NVMe Samsung 980 1TB ($310.000 — 25 uds.) — Almacenamiento
8. **RAM-008**: Memoria RAM Corsair Vengeance 16GB DDR4 ($185.000 — 40 uds.) — Componentes
9. **SL-009**: Silla Ergonómica Herman Miller Sayl ($2.400.000 — 6 uds.) — Mobiliario
10. **CAM-010**: Cámara Web Logitech Brio 4K ($750.000 — 18 uds.) — Video

---

## 5. Endpoints de la API REST

| Método | Endpoint | Funcionalidad | Respuestas HTTP |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/productos` | Listar todos los productos (con filtros opcionales de búsqueda y categoría) | `200 OK` |
| `GET` | `/api/productos/{id}` | Consultar el detalle de un producto específico | `200 OK`, `404 Not Found` |
| `POST` | `/api/productos` | Registrar un nuevo producto con código único | `201 Created`, `400 Bad Request`, `422 Unprocessable` |
| `PUT` | `/api/productos/{id}` | Actualizar un producto existente | `200 OK`, `400 Bad Request`, `404 Not Found` |
| `DELETE` | `/api/productos/{id}` | Eliminar un producto por ID | `200 OK`, `404 Not Found` |
| `GET` | `/api/dashboard` | Obtener métricas consolidadas del inventario | `200 OK` |

### 5.1. Ejemplos de Peticiones y Respuestas JSON

#### A. Listar productos (`GET /api/productos`)
**Respuesta:** `200 OK`
```json
[
  {
    "id": 1,
    "nombre": "Laptop Lenovo ThinkPad T14",
    "codigo": "LP-001",
    "descripcion": "Portátil corporativo Intel Core i7, 16GB RAM, SSD 512GB",
    "precio": 3450000.0,
    "cantidad": 12,
    "categoria": "Tecnología"
  },
  {
    "id": 2,
    "nombre": "Mouse Inalámbrico Logitech MX Master 3",
    "codigo": "MS-002",
    "descripcion": "Mouse ergonómico inalámbrico con sensor Darkfield 4000 DPI",
    "precio": 380000.0,
    "cantidad": 35,
    "categoria": "Accesorios"
  }
]
```

#### B. Registrar producto (`POST /api/productos`)
**Cuerpo de la Petición:**
```json
{
  "nombre": "Tablet Samsung Galaxy Tab S9",
  "codigo": "TAB-015",
  "descripcion": "Pantalla Dynamic AMOLED 2X, 128GB, S-Pen incluido",
  "precio": 2950000.0,
  "cantidad": 9,
  "categoria": "Tecnología"
}
```
**Respuesta:** `201 Created`
```json
{
  "id": 11,
  "nombre": "Tablet Samsung Galaxy Tab S9",
  "codigo": "TAB-015",
  "descripcion": "Pantalla Dynamic AMOLED 2X, 128GB, S-Pen incluido",
  "precio": 2950000.0,
  "cantidad": 9,
  "categoria": "Tecnología"
}
```

#### C. Intentar registrar código duplicado (`POST /api/productos`)
**Respuesta:** `400 Bad Request`
```json
{
  "detail": "Ya existe un producto con el código 'TAB-015'."
}
```

#### D. Actualizar producto (`PUT /api/productos/{id}`)
**Cuerpo de la Petición:**
```json
{
  "precio": 2850000.0,
  "cantidad": 14
}
```
**Respuesta:** `200 OK`
```json
{
  "id": 11,
  "nombre": "Tablet Samsung Galaxy Tab S9",
  "codigo": "TAB-015",
  "descripcion": "Pantalla Dynamic AMOLED 2X, 128GB, S-Pen incluido",
  "precio": 2850000.0,
  "cantidad": 14,
  "categoria": "Tecnología"
}
```

#### E. Eliminar producto (`DELETE /api/productos/{id}`)
**Respuesta:** `200 OK`
```json
{
  "mensaje": "Producto 'Tablet Samsung Galaxy Tab S9' con ID 11 eliminado exitosamente.",
  "producto": {
    "id": 11,
    "nombre": "Tablet Samsung Galaxy Tab S9",
    "codigo": "TAB-015",
    "descripcion": "Pantalla Dynamic AMOLED 2X, 128GB, S-Pen incluido",
    "precio": 2850000.0,
    "cantidad": 14,
    "categoria": "Tecnología"
  }
}
```

#### F. Estadísticas del Dashboard (`GET /api/dashboard`)
**Respuesta:** `200 OK`
```json
{
  "total_productos": 10,
  "total_unidades": 184,
  "valor_total_inventario": 178770000.0
}
```

---

## 6. Frontend Flutter — Pantallas y Funcionalidades

### 6.1. Dashboard Principal
* **Identificación visual:** Logotipo, nombre comercial y banner informativo.
* **Tarjeta 1:** Total de productos registrados en la base de datos.
* **Tarjeta 2:** Total de unidades físicas acumuladas en inventario.
* **Tarjeta 3:** Valor económico total del inventario, calculado mediante:
  $$\text{Valor Total} = \sum_{i=1}^{n} (\text{precio}_i \times \text{cantidad}_i)$$
* **Acceso rápido:** Botones directos a "Ver Productos" y "Nuevo Producto".
* **Alertas de stock:** Lista reactiva de productos con stock crítico ($\le 5$ unidades).
* **Actualización en vivo:** Pull-to-refresh para sincronizar instantáneamente.

### 6.2. Catálogo de Productos (CRUD Completo)
* **Listado:** Muestra cada producto con nombre, categoría, código, precio unitario y cantidad disponible.
* **Búsqueda en tiempo real:** Filtro por coincidencia de texto en nombre o código.
* **Filtros por categoría:** Barra horizontal de chips de categorías.
* **Consulta (Detalle):** Pantalla dedicada con todos los datos técnicos y valor del stock del producto.
* **Registro (POST):** Formulario con validación de entradas obligatorias, tipos de datos y unicidad de código.
* **Edición (PUT):** Carga los datos previos en el formulario y envía las modificaciones.
* **Eliminación (DELETE):** Modal de confirmación con diálogo de advertencia antes de eliminar.

### 6.3. Navegación y Buenas Prácticas
* **go_router:** Configuración jerárquica con `ShellRoute`, URLs limpias y navegación desacoplada.
* **Dio Client:** Peticiones asíncronas con timeout, interceptores y traducción amigable de errores.
* **flutter_dotenv:** Carga de variables de entorno desde `.env` con soporte automático para Emulador Android (`10.0.2.2`) y Windows/Web (`127.0.0.1`).
* **Provider:** Separación absoluta entre widgets de presentación y lógica de comunicación HTTP.

---

## 7. Instrucciones de Instalación y Ejecución

### 7.1. Requisitos Previos
* **Python 3.10+** instalado y en el PATH del sistema.
* **Flutter SDK 3.20+** instalado y configurado.

---

### 7.2. Ejecutar el Backend (FastAPI + SQLite)

#### Opción Rápida (Windows):
Haga doble clic en el archivo `run_backend.bat` en la raíz del proyecto.

#### Opción Manual:
```bash
# 1. Navegar a la carpeta del backend
cd backend

# 2. Instalar dependencias
pip install -r requirements.txt

# 3. Iniciar el servidor
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

* **API activa en:** `http://127.0.0.1:8000`
* **Swagger UI interactivo:** `http://127.0.0.1:8000/docs`
* **ReDoc:** `http://127.0.0.1:8000/redoc`

---

### 7.3. Ejecutar el Frontend (Flutter)

#### Opción Rápida (Windows):
Haga doble clic en el archivo `run_frontend.bat` en la raíz del proyecto.

#### Opción Manual:
```bash
# 1. Navegar a la carpeta de Flutter
cd frontend

# 2. Instalar paquetes de Flutter
flutter pub get

# 3. Ejecutar en el dispositivo deseado:
# Para Google Chrome (Web):
flutter run -d chrome

# Para Windows Desktop:
flutter run -d windows

# Para Emulador de Android:
flutter run -d emulator
```

> **Nota sobre `.env`:** El archivo `frontend/.env` ya viene configurado por defecto con:
> `API_BASE_URL=http://127.0.0.1:8000/api`
> Si ejecuta en un emulador Android físico o virtual, la aplicación detectará la plataforma automáticamente y redirigirá a `http://10.0.2.2:8000/api`.

---

## 8. Guía para la Grabación del Video Explicativo

Para cumplir con el 100% de los requisitos del video explicativo:

1. **Introducción (1 min):**
   * Presentación del estudiante (Brahian Andres Tenorio), materia y objetivo del proyecto.
   * Mostrar brevemente la estructura de carpetas en el editor (`backend/` y `frontend/`).
2. **Explicación del Backend (2 min):**
   * Explicar el archivo `database.py` (persistencia real con SQLite y tabla `productos`).
   * Explicar `models.py` (Pydantic schemas) y `main.py` (los 5 endpoints obligatorios + dashboard).
3. **Pruebas de la API con Swagger UI (2 min):**
   * Abrir el navegador en `http://127.0.0.1:8000/docs`.
   * Probar `GET /api/productos` (ver los 10 productos iniciales).
   * Probar `POST /api/productos` (crear uno nuevo y verificar respuesta 201).
   * Probar validación con código repetido (ver respuesta 400).
   * Probar `PUT /api/productos/{id}` y `DELETE /api/productos/{id}`.
4. **Explicación de Flutter (2 min):**
   * Mostrar el uso de `Dio` en `producto_service.dart`.
   * Mostrar la configuración de rutas con `go_router` en `app_router.dart`.
   * Mostrar la carga de `API_BASE_URL` con `flutter_dotenv` en `api_config.dart`.
   * Mostrar el Provider `inventario_provider.dart` como intermediario entre la UI y el servicio.
5. **Demostración Funcional en la Aplicación (3-4 min):**
   * **Dashboard:** Mostrar los 3 indicadores reales (total productos, total unidades, valor económico).
   * **Listado:** Mostrar los productos cargados, barra de búsqueda y filtros.
   * **Detalle:** Seleccionar un producto y consultar toda su información técnica.
   * **Registro:** Crear un nuevo producto desde la app y verificar que aparece en la lista y las tarjetas del Dashboard se actualizan.
   * **Edición:** Modificar el precio o cantidad de un producto existente y verificar el cambio.
   * **Eliminación:** Eliminar un producto confirmando en el modal y ver cómo se descuenta del inventario.
   * **Persistencia:** Cerrar el backend y volverlo a iniciar para demostrar que los datos persisten intactos en SQLite.

---

## 9. Criterios de Evaluación Cubiertos

| Requisito | Estado | Justificación Técnica |
| :--- | :---: | :--- |
| **API REST Propia** | Cumplido | Implementada con FastAPI y Python con respuestas JSON y códigos HTTP estrictos. |
| **Persistencia Real en BD** | Cumplido | Base de datos SQLite permanente en disco (`inventario.db`) con 10 productos sembrados. |
| **CRUD Completo con Dio** | Cumplido | Métodos GET, POST, PUT, DELETE consumidos a través de `dio: ^5.11.1`. |
| **Dashboard con Indicadores** | Cumplido | Conteo de productos, suma de stock y cálculo de valor total $\sum(\text{precio}\times\text{cantidad})$. |
| **Navegación con go_router** | Cumplido | Rutas declarativas estructuradas con `ShellRoute` y paso de parámetros por path. |
| **Configuración con .env** | Cumplido | Uso obligatorio de `flutter_dotenv` para desacoplar la URL del backend. |
| **Separación de Responsabilidades** | Cumplido | Capas independientes: Modelos, Servicios, Providers, Vistas y Componentes UI. |
| **Validaciones y Errores** | Cumplido | Formularios validados en Flutter y manejo de códigos 400, 404, 422 y 500 en español. |
| **Pruebas y Automatización** | Cumplido | Scripts `.bat` para ejecución en 1 clic y suite de pruebas unitarias (`flutter test`). |
