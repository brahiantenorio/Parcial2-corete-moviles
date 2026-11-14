from fastapi import FastAPI, HTTPException, status, Query, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from typing import List, Optional
import sqlite3

from database import get_db_connection, init_db
from auth import (
    get_current_user,
    verify_password,
    create_access_token,
    ACCESS_TOKEN_EXPIRE_HOURS,
)
from models import (
    ProductoCreate,
    ProductoUpdate,
    ProductoResponse,
    DashboardStats,
    MensajeResponse,
    LoginRequest,
    UserResponse,
    TokenResponse,
    SessionStatusResponse,
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Inicializar la base de datos al arrancar (tablas de productos y usuarios)
    init_db()
    yield

app = FastAPI(
    title="API REST de Gestión de Inventario con Autenticación JWT",
    description="Backend oficial con persistencia SQLite y protección JWT para Electiva Profesional I (Desarrollo Móvil)",
    version="2.0.0",
    lifespan=lifespan
)

# Configuración de CORS para permitir conexiones desde Flutter (Web, Emulador Android, Windows Desktop, Móvil Físico)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================================
# Rutas Públicas y Documentación
# ============================================================================

@app.get("/", tags=["General"])
def read_root():
    """Ruta raíz de bienvenida e información de la API."""
    return {
        "sistema": "API REST - Sistema de Gestión de Inventario con JWT",
        "asignatura": "Electiva Profesional I - Desarrollo Móvil",
        "evaluacion": "Taller: Autenticación JWT y Protección de Servicios",
        "estudiante": "Brahian Andres Tenorio",
        "estado": "Activo y Protegido (JWT + SQLite)",
        "documentacion_swagger": "/docs",
        "documentacion_redoc": "/redoc",
        "usuarios_de_prueba": [
            {
                "email": "brahian.tenorio@uceva.edu.co",
                "password": "admin123",
                "rol": "admin"
            },
            {
                "email": "profesor@uceva.edu.co",
                "password": "profe2026",
                "rol": "docente"
            },
            {
                "email": "usuario@test.com",
                "password": "123456",
                "rol": "usuario"
            }
        ],
        "endpoints_autenticacion": {
            "login": "POST /api/auth/login",
            "perfil_actual": "GET /api/auth/me (Protegido)",
            "verificar_token": "GET /api/auth/verify (Protegido)"
        },
        "endpoints_protegidos": {
            "dashboard": "GET /api/dashboard",
            "listar_productos": "GET /api/productos",
            "detalle_producto": "GET /api/productos/{id}",
            "crear_producto": "POST /api/productos",
            "actualizar_producto": "PUT /api/productos/{id}",
            "eliminar_producto": "DELETE /api/productos/{id}"
        }
    }

# ============================================================================
# Endpoints de Autenticación JWT
# ============================================================================

@app.post("/api/auth/login", response_model=TokenResponse, tags=["Autenticación"])
def login(credentials: LoginRequest):
    """
    Endpoint de inicio de sesión:
    - Valida las credenciales (correo electrónico y contraseña) contra la base de datos SQLite.
    - Si son correctas, genera y retorna un token JWT firmado con algoritmo HS256.
    - Si son incorrectas, rechaza la petición con código HTTP 401 Unauthorized y mensaje explicativo.
    """
    email_clean = credentials.email.strip().lower()
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT id, nombre, email, password_hash, rol, activo FROM usuarios WHERE LOWER(email) = ?",
        (email_clean,)
    )
    user_row = cursor.fetchone()
    conn.close()

    if not user_row or not verify_password(credentials.password, user_row["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales incorrectas: Correo electrónico o contraseña no válidos.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user_row["activo"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="La cuenta de usuario está inactiva. Contacte al administrador.",
        )

    # Generar token JWT con claims requeridos
    token_data = {
        "sub": str(user_row["id"]),
        "email": user_row["email"],
        "nombre": user_row["nombre"],
        "rol": user_row["rol"],
    }
    access_token = create_access_token(token_data)

    user_response = UserResponse(
        id=user_row["id"],
        nombre=user_row["nombre"],
        email=user_row["email"],
        rol=user_row["rol"],
    )

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=ACCESS_TOKEN_EXPIRE_HOURS * 3600,
        user=user_response
    )

@app.get("/api/auth/me", response_model=UserResponse, tags=["Autenticación"])
def get_me(current_user: dict = Depends(get_current_user)):
    """
    Endpoint protegido: Obtiene la información del usuario actualmente autenticado
    a partir del token JWT enviado en el encabezado Authorization.
    """
    return UserResponse(
        id=current_user["id"],
        nombre=current_user["nombre"],
        email=current_user["email"],
        rol=current_user["rol"],
    )

@app.get("/api/auth/verify", response_model=SessionStatusResponse, tags=["Autenticación"])
def verify_session(current_user: dict = Depends(get_current_user)):
    """
    Endpoint protegido: Verifica la validez del token JWT almacenado.
    Permite a la aplicación comprobar si la sesión aún es válida al iniciarse.
    """
    return SessionStatusResponse(
        autenticado=True,
        user=UserResponse(
            id=current_user["id"],
            nombre=current_user["nombre"],
            email=current_user["email"],
            rol=current_user["rol"],
        ),
        mensaje="Sesión activa y token JWT válido."
    )

# ============================================================================
# Endpoints Protegidos del Inventario (CRUD y Dashboard)
# Requieren encabezado 'Authorization: Bearer <token>' válido
# ============================================================================

@app.get("/api/dashboard", response_model=DashboardStats, tags=["Dashboard (Protegido)"])
def get_dashboard_stats(current_user: dict = Depends(get_current_user)):
    """
    Endpoint protegido: Retorna métricas consolidadas en tiempo real para las tarjetas del Dashboard.
    Requiere autenticación con JWT.
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT 
            COUNT(*) AS total_productos,
            COALESCE(SUM(cantidad), 0) AS total_unidades,
            COALESCE(SUM(precio * cantidad), 0.0) AS valor_total_inventario
        FROM productos
    """)
    row = cursor.fetchone()
    conn.close()

    return DashboardStats(
        total_productos=row["total_productos"],
        total_unidades=row["total_unidades"],
        valor_total_inventario=float(row["valor_total_inventario"])
    )

@app.get("/api/productos", response_model=List[ProductoResponse], tags=["Productos (Protegido)"])
def list_productos(
    q: Optional[str] = Query(None, description="Término de búsqueda por nombre o código"),
    categoria: Optional[str] = Query(None, description="Filtrar por categoría"),
    current_user: dict = Depends(get_current_user)
):
    """
    Endpoint protegido: Listar todos los productos registrados.
    Permite opcionalmente filtrar por término de búsqueda (nombre/código) o categoría.
    Requiere autenticación con JWT.
    """
    conn = get_db_connection()
    cursor = conn.cursor()

    query = "SELECT id, nombre, codigo, descripcion, precio, cantidad, categoria FROM productos WHERE 1=1"
    params = []

    if q:
        query += " AND (nombre LIKE ? OR codigo LIKE ?)"
        term = f"%{q.strip()}%"
        params.extend([term, term])

    if categoria:
        query += " AND categoria = ?"
        params.append(categoria.strip())

    query += " ORDER BY id DESC"

    cursor.execute(query, params)
    rows = cursor.fetchall()
    conn.close()

    return [dict(row) for row in rows]

@app.get("/api/productos/{producto_id}", response_model=ProductoResponse, tags=["Productos (Protegido)"])
def get_producto(producto_id: int, current_user: dict = Depends(get_current_user)):
    """
    Endpoint protegido: Consultar el detalle completo de un producto por su ID.
    Retorna 404 si el producto no existe.
    Requiere autenticación con JWT.
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT id, nombre, codigo, descripcion, precio, cantidad, categoria FROM productos WHERE id = ?",
        (producto_id,)
    )
    row = cursor.fetchone()
    conn.close()

    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Producto con ID {producto_id} no encontrado en el sistema."
        )

    return dict(row)

@app.post("/api/productos", response_model=ProductoResponse, status_code=status.HTTP_201_CREATED, tags=["Productos (Protegido)"])
def create_producto(producto: ProductoCreate, current_user: dict = Depends(get_current_user)):
    """
    Endpoint protegido: Registrar un nuevo producto en la base de datos.
    Valida campos, código único, precio y cantidad.
    Requiere autenticación con JWT.
    """
    conn = get_db_connection()
    cursor = conn.cursor()

    # Validar unicidad del código
    cursor.execute("SELECT id FROM productos WHERE codigo = ?", (producto.codigo.strip(),))
    if cursor.fetchone():
        conn.close()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Ya existe un producto con el código '{producto.codigo.strip()}'."
        )

    try:
        cursor.execute("""
            INSERT INTO productos (nombre, codigo, descripcion, precio, cantidad, categoria)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            producto.nombre.strip(),
            producto.codigo.strip().upper(),
            producto.descripcion.strip() if producto.descripcion else None,
            producto.precio,
            producto.cantidad,
            producto.categoria.strip()
        ))
        conn.commit()
        nuevo_id = cursor.lastrowid
        
        # Recuperar producto insertado
        cursor.execute("SELECT id, nombre, codigo, descripcion, precio, cantidad, categoria FROM productos WHERE id = ?", (nuevo_id,))
        nuevo_producto = cursor.fetchone()
        conn.close()
        return dict(nuevo_producto)
    except sqlite3.IntegrityError as e:
        conn.close()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error de integridad en los datos: {str(e)}"
        )
    except Exception as e:
        conn.close()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error inesperado al guardar el producto: {str(e)}"
        )

@app.put("/api/productos/{producto_id}", response_model=ProductoResponse, tags=["Productos (Protegido)"])
def update_producto(producto_id: int, producto: ProductoUpdate, current_user: dict = Depends(get_current_user)):
    """
    Endpoint protegido: Actualizar un producto existente.
    Requiere autenticación con JWT.
    """
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT id, nombre, codigo, descripcion, precio, cantidad, categoria FROM productos WHERE id = ?", (producto_id,))
    actual = cursor.fetchone()
    if not actual:
        conn.close()
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No se puede actualizar: Producto con ID {producto_id} no existe."
        )

    # Si se actualiza el código, verificar que no colisione con otro producto
    if producto.codigo:
        nuevo_codigo = producto.codigo.strip().upper()
        cursor.execute("SELECT id FROM productos WHERE codigo = ? AND id != ?", (nuevo_codigo, producto_id))
        if cursor.fetchone():
            conn.close()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"El código '{nuevo_codigo}' ya está asignado a otro producto."
            )

    nombre = producto.nombre.strip() if producto.nombre is not None else actual["nombre"]
    codigo = producto.codigo.strip().upper() if producto.codigo is not None else actual["codigo"]
    descripcion = producto.descripcion.strip() if producto.descripcion is not None else actual["descripcion"]
    precio = producto.precio if producto.precio is not None else actual["precio"]
    cantidad = producto.cantidad if producto.cantidad is not None else actual["cantidad"]
    categoria = producto.categoria.strip() if producto.categoria is not None else actual["categoria"]

    try:
        cursor.execute("""
            UPDATE productos 
            SET nombre = ?, codigo = ?, descripcion = ?, precio = ?, cantidad = ?, categoria = ?
            WHERE id = ?
        """, (nombre, codigo, descripcion, precio, cantidad, categoria, producto_id))
        conn.commit()

        cursor.execute("SELECT id, nombre, codigo, descripcion, precio, cantidad, categoria FROM productos WHERE id = ?", (producto_id,))
        producto_actualizado = cursor.fetchone()
        conn.close()
        return dict(producto_actualizado)
    except sqlite3.IntegrityError as e:
        conn.close()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error de integridad en base de datos: {str(e)}"
        )
    except Exception as e:
        conn.close()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error inesperado al actualizar el producto: {str(e)}"
        )

@app.delete("/api/productos/{producto_id}", response_model=MensajeResponse, tags=["Productos (Protegido)"])
def delete_producto(producto_id: int, current_user: dict = Depends(get_current_user)):
    """
    Endpoint protegido: Eliminar un producto por su ID.
    Requiere autenticación con JWT.
    """
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT id, nombre, codigo, descripcion, precio, cantidad, categoria FROM productos WHERE id = ?", (producto_id,))
    actual = cursor.fetchone()
    if not actual:
        conn.close()
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No se puede eliminar: Producto con ID {producto_id} no fue encontrado."
        )

    producto_dict = dict(actual)
    cursor.execute("DELETE FROM productos WHERE id = ?", (producto_id,))
    conn.commit()
    conn.close()

    return MensajeResponse(
        mensaje=f"Producto '{producto_dict['nombre']}' con ID {producto_id} eliminado exitosamente.",
        producto=ProductoResponse(**producto_dict)
    )

if __name__ == "__main__":
    import uvicorn
    # Inicializar DB y correr servidor local
    init_db()
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
