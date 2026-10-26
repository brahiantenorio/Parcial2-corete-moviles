# INFORME DE EVIDENCIAS — SEGUNDO PARCIAL PRÁCTICO
## Sistema de Gestión de Inventario — API REST + Flutter
**Asignatura:** Electiva Profesional I — Desarrollo de Aplicaciones Móviles  
**Docente:** Electiva Profesional I  
**Periodo:** Segundo Corte  

---

### 1. Identificación del Estudiante
* **Nombre:** Brahian Andres Tenorio
* **Programa:** Ingeniería de Sistemas
* **Enlace al Repositorio de GitHub:** [https://github.com/brahiantenorio/Parcial2-corete-moviles](https://github.com/brahiantenorio/Parcial2-corete-moviles)
* **Enlace al Video Explicativo:** [https://canva.link/d38e23vkby9s0rd](https://canva.link/d38e23vkby9s0rd) *(o enlace a Google Drive / YouTube)*

---

### 2. Descripción de las Tecnologías Utilizadas

#### Backend (API REST)
* **Python 3.14 + FastAPI:** Framework moderno y de alto rendimiento que permite la construcción rápida de servicios web RESTful, con validación automática de esquemas mediante Pydantic y documentación OpenAPI interactiva en `/docs`.
* **SQLite:** Sistema gestor de base de datos relacional ligero y embebido con persistencia completa en disco (`inventario.db`). Proporciona soporte ACID sin depender de software o servicios adicionales en Windows.
* **Uvicorn:** Servidor ASGI para Python de alto desempeño que atiende las peticiones HTTP y maneja CORS para la interacción con Flutter.

#### Frontend (Aplicación Móvil Flutter)
* **Flutter SDK 3.47 + Dart 3.13:** Toolkit para el desarrollo de interfaces nativas compiladas.
* **Dio (`^5.11.1`):** Cliente HTTP potente que implementa interceptores, configuración de timeouts globales y manejo estructurado de excepciones de red (`DioException`).
* **go_router (`^18.1.1`):** Enrutador declarativo oficial de Flutter que administra la navegación jerárquica mediante `ShellRoute` y paso de parámetros dinámicos por URL.
* **flutter_dotenv (`^6.0.1`):** Carga segura de variables de configuración (`.env`) para desacoplar la dirección IP y puerto del backend.
* **Provider (`^6.1.5`):** Gestión reactiva del estado de la aplicación, separando completamente los widgets de presentación de la capa lógica y de comunicación.
* **Intl (`^0.20.3`):** Formateo localizado de divisas (pesos colombianos) y cantidades numéricas.

---

### 3. Evidencia de la Base de Datos y Persistencia

#### Estructura de la Tabla `productos` en SQLite:
```sql
CREATE TABLE productos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    codigo TEXT NOT NULL UNIQUE,
    descripcion TEXT,
    precio REAL NOT NULL CHECK(precio > 0),
    cantidad INTEGER NOT NULL CHECK(cantidad >= 0),
    categoria TEXT NOT NULL
);
```

* **Persistencia comprobada:** Los datos se escriben directamente en el archivo `backend/inventario.db`. Cuando el servidor se reinicia o se apaga la máquina, los productos creados o editados permanecen almacenados de forma permanente.
* **Semilla inicial:** Contiene 10 productos de prueba clasificados en categorías (Tecnología, Accesorios, Monitores, Audio, Oficina, Componentes, Mobiliario, Video).

---

### 4. Evidencias de los Endpoints del Backend

A continuación se resumen los 5 endpoints obligatorios probados mediante Swagger UI (`http://127.0.0.1:8000/docs`):

1. **GET `/api/productos`**: Lista todas las referencias de productos registradas en la base de datos con código HTTP `200 OK`.
2. **GET `/api/productos/{id}`**: Obtiene el detalle de un único producto. Retorna `200 OK` con el objeto correspondiente o `404 Not Found` si el ID no existe.
3. **POST `/api/productos`**: Registra un nuevo producto. Valida que el código sea único (retorna `400 Bad Request` en caso de duplicidad) y que el precio y cantidad sean válidos. Retorna `201 Created`.
4. **PUT `/api/productos/{id}`**: Actualiza los datos de un producto existente. Valida la existencia del ID (`404`) y que el código no colisione con otro producto. Retorna `200 OK`.
5. **DELETE `/api/productos/{id}`**: Elimina de manera definitiva un producto de la base de datos previa validación de existencia. Retorna `200 OK` confirmando la eliminación.
6. **GET `/api/dashboard`**: Endpoint adicional que entrega el resumen cuantitativo en tiempo real del inventario.

---

### 5. Evidencias del Frontend Móvil Flutter

#### A. Dashboard Principal
* Presenta el nombre del establecimiento, navegación por menú lateral (Drawer) e inferior (NavigationBar).
* **Tarjeta 1:** Total de productos únicos registrados.
* **Tarjeta 2:** Total de unidades físicas disponibles en bodega.
* **Tarjeta 3:** Valor económico consolidado de todo el inventario, resultado de la suma de `(precio * cantidad)` de cada ítem.
* **Alertas:** Notificación de existencias críticas (productos con stock $\le 5$).

#### B. Catálogo de Productos
* Lista de productos con tarjetas personalizadas. Cada tarjeta exhibe el nombre, código único, categoría, precio formateado y badge de disponibilidad.
* Barra de búsqueda reactiva por nombre y código.
* Filtros rápidos horizontales por categoría.

#### C. Detalle de Producto
* Vista completa con ID del sistema, código SKU, categoría, precio, stock, valor acumulado de existencias y descripción detallada.
* Botones directos para editar o eliminar.

#### D. Formulario de Registro y Edición (CRUD)
* Validación en tiempo real de campos obligatorios.
* Control estricto de números positivos para precios y enteros para stock.
* Notificaciones tipo SnackBar en la parte inferior para confirmar el éxito de las operaciones o reportar errores claros devueltos por la API.
* Diálogo de alerta (`AlertDialog`) antes de confirmar cualquier eliminación.

---

### 6. Conclusiones
La solución desarrollada cumple a cabalidad con todos los lineamientos pedagógicos y técnicos exigidos en la rúbrica de evaluación:
* Desacoplamiento total entre Backend y Frontend.
* Persistencia real y confiable sin simulaciones locales volátiles.
* Cumplimiento estricto del uso de `dio`, `go_router` y `flutter_dotenv`.
* Código limpio, documentado, estructurado y versionado con Git y GitHub.
