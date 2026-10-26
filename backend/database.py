import sqlite3
import os
from typing import Generator

DB_PATH = os.path.join(os.path.dirname(__file__), "inventario.db")

def get_db_connection() -> sqlite3.Connection:
    """Crea y retorna una conexión a la base de datos SQLite."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db() -> None:
    """Inicializa la base de datos creando la tabla productos y sembrando datos iniciales."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Crear tabla de productos
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            codigo TEXT NOT NULL UNIQUE,
            descripcion TEXT,
            precio REAL NOT NULL CHECK(precio > 0),
            cantidad INTEGER NOT NULL CHECK(cantidad >= 0),
            categoria TEXT NOT NULL
        )
    """)
    conn.commit()

    # Verificar si ya existen productos
    cursor.execute("SELECT COUNT(*) AS total FROM productos")
    total = cursor.fetchone()["total"]
    
    if total == 0:
        print("[DATABASE] Base de datos vacía. Insertando 10 productos de prueba iniciales...")
        productos_iniciales = [
            ("Laptop Lenovo ThinkPad T14", "LP-001", "Portátil corporativo Intel Core i7, 16GB RAM, SSD 512GB", 3450000.0, 12, "Tecnología"),
            ("Mouse Inalámbrico Logitech MX Master 3", "MS-002", "Mouse ergonómico inalámbrico con sensor Darkfield 4000 DPI", 380000.0, 35, "Accesorios"),
            ("Teclado Mecánico Keychron K2 RGB", "KB-003", "Teclado mecánico 75% inalámbrico con switches Gateron Brown", 420000.0, 20, "Accesorios"),
            ("Monitor Dell 27 4K UHD", "MN-004", "Monitor IPS 27 pulgadas resolución 3840x2160 con USB-C 65W", 1750000.0, 15, "Monitores"),
            ("Auriculares Sony WH-1000XM5", "AU-005", "Audífonos inalámbricos con cancelación de ruido líder en la industria", 1450000.0, 10, "Audio"),
            ("Impresora Multifuncional Epson EcoTank L3250", "IMP-006", "Impresora a color tanque de tinta continua WiFi y escáner", 890000.0, 8, "Oficina"),
            ("Disco Sólido SSD NVMe Samsung 980 1TB", "SSD-007", "Almacenamiento ultra rápido PCIe 3.0 M.2 hasta 3500 MB/s", 310000.0, 25, "Almacenamiento"),
            ("Memoria RAM Corsair Vengeance 16GB DDR4", "RAM-008", "Módulo de memoria DDR4 3200MHz con disipador de aluminio", 185000.0, 40, "Componentes"),
            ("Silla Ergonómica Herman Miller Sayl", "SL-009", "Silla ergonómica de diseño con soporte lumbar ajustable", 2400000.0, 6, "Mobiliario"),
            ("Cámara Web Logitech Brio 4K", "CAM-010", "Webcam Ultra HD 4K con HDR y encuadre inteligente RightLight", 750000.0, 18, "Video")
        ]
        cursor.executemany("""
            INSERT INTO productos (nombre, codigo, descripcion, precio, cantidad, categoria)
            VALUES (?, ?, ?, ?, ?, ?)
        """, productos_iniciales)
        conn.commit()
        print(f"[DATABASE] {len(productos_iniciales)} productos insertados exitosamente.")
    else:
        print(f"[DATABASE] Base de datos lista. {total} productos registrados.")

    conn.close()
