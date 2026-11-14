import sqlite3
import os
import hashlib
import secrets

DB_PATH = os.path.join(os.path.dirname(__file__), "inventario.db")

def _hash_seed_password(password: str) -> str:
    """Función auxiliar para generar hash de contraseñas de semilla sin dependencias circulares."""
    salt = secrets.token_hex(16)
    pwd_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        iterations=100000
    ).hex()
    return f"{salt}${pwd_hash}"

def get_db_connection() -> sqlite3.Connection:
    """Crea y retorna una conexión a la base de datos SQLite."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db() -> None:
    """Inicializa la base de datos creando las tablas de productos y usuarios y sembrando datos iniciales."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # 1. Crear tabla de productos
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

    # 2. Crear tabla de usuarios para autenticación JWT
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            rol TEXT DEFAULT 'admin',
            activo INTEGER DEFAULT 1
        )
    """)
    conn.commit()

    # Verificar y sembrar usuarios iniciales
    cursor.execute("SELECT COUNT(*) AS total FROM usuarios")
    total_usuarios = cursor.fetchone()["total"]
    if total_usuarios == 0:
        print("[DATABASE] Base de datos: Sembrando usuarios de prueba para autenticación...")
        usuarios_iniciales = [
            (
                "Brahian Andres Tenorio",
                "brahian.tenorio@uceva.edu.co",
                _hash_seed_password("admin123"),
                "admin",
                1
            ),
            (
                "Docente Evaluador",
                "profesor@uceva.edu.co",
                _hash_seed_password("profe2026"),
                "docente",
                1
            ),
            (
                "Usuario de Prueba",
                "usuario@test.com",
                _hash_seed_password("123456"),
                "usuario",
                1
            ),
        ]
        cursor.executemany("""
            INSERT INTO usuarios (nombre, email, password_hash, rol, activo)
            VALUES (?, ?, ?, ?, ?)
        """, usuarios_iniciales)
        conn.commit()
        print(f"[DATABASE] {len(usuarios_iniciales)} usuarios creados exitosamente.")
    else:
        print(f"[DATABASE] Tabla usuarios lista: {total_usuarios} usuarios registrados.")

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
