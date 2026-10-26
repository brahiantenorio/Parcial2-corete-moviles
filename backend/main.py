from fastapi import FastAPI, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from typing import List, Optional
import sqlite3

from database import get_db_connection, init_db
from models import (
    ProductoCreate,
    ProductoUpdate,
    ProductoResponse,
    DashboardStats,
    MensajeResponse,
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Inicializar la base de datos al arrancar
    init_db()
    yield

app = FastAPI(
    title="API REST de Gestión de Inventario",
    description="Backend oficial con persistencia SQLite para el Parcial 2 - Electiva Profesional I (Desarrollo Móvil)",
    version="1.0.0",
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

@app.get("/", tags=["General"])
def read_root():
    """Ruta raíz de bienvenida e información de la API."""
    return {
        "sistema": "API REST - Sistema de Gestión de Inventario",
        "asignatura": "Electiva Profesional I - Desarrollo Móvil",
        "evaluacion": "Segundo Parcial Práctico",
        "estudiante": "Brahian Andres Tenorio",
        "estado": "Activo y Persistente (SQLite)",
        "documentacion_swagger": "/docs",
        "documentacion_redoc": "/redoc",
        "endpoints_principales": {
            "listar_productos": "GET /api/productos",
            "detalle_producto": "GET /api/productos/{id}",
            "crear_producto": "POST /api/productos",
            "actualizar_producto": "PUT /api/productos/{id}",
            "eliminar_producto": "DELETE /api/productos/{id}",
            "estadisticas_dashboard": "GET /api/dashboard"
        }
    }

@app.get("/api/dashboard", response_model=DashboardStats, tags=["Dashboard"])
def get_dashboard_stats():
    """
    Retorna métricas consolidadas en tiempo real para las tarjetas del Dashboard:
    - total_productos: Conteo total de productos registrados
    - total_unidades: Suma total de unidades en stock
    - valor_total_inventario: Suma de (precio * cantidad) de cada producto
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

@app.get("/api/productos", response_model=List[ProductoResponse], tags=["Productos"])
def list_productos(
    q: Optional[str] = Query(None, description="Término de búsqueda por nombre o código"),
    categoria: Optional[str] = Query(None, description="Filtrar por categoría")
):
    """
    Endpoint 1 obligatorio: Listar todos los productos registrados.
    Permite opcionalmente filtrar por término de búsqueda (nombre/código) o categoría.
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

@app.get("/api/productos/{producto_id}", response_model=ProductoResponse, tags=["Productos"])
def get_producto(producto_id: int):
    """
    Endpoint 2 obligatorio: Consultar el detalle completo de un producto por su ID.
    Retorna 404 si el producto no existe.
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

@app.post("/api/productos", response_model=ProductoResponse, status_code=status.HTTP_201_CREATED, tags=["Productos"])
def create_producto(producto: ProductoCreate):
    """
    Endpoint 3 obligatorio: Registrar un nuevo producto en la base de datos.
    Valida:
    - Campos requeridos y formatos
    - Código único (retorna 400 si ya está registrado)
    - Precio > 0 y Cantidad >= 0
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

@app.put("/api/productos/{producto_id}", response_model=ProductoResponse, tags=["Productos"])
def update_producto(producto_id: int, producto: ProductoUpdate):
    """
    Endpoint 4 obligatorio: Actualizar un producto existente.
    Valida:
    - Que el producto exista (404)
    - Que el nuevo código no esté ocupado por otro producto (400)
    - Valores coherentes de precio y cantidad
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

@app.delete("/api/productos/{producto_id}", response_model=MensajeResponse, tags=["Productos"])
def delete_producto(producto_id: int):
    """
    Endpoint 5 obligatorio: Eliminar un producto por su ID.
    Valida que el producto exista (404 si no existe).
    Retorna mensaje confirmando la eliminación y los datos del producto eliminado.
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
