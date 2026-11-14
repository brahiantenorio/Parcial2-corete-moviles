"""
Suite de Pruebas Automatizadas de Autenticación JWT y Protección de Endpoints
Asignatura: Electiva Profesional I - Desarrollo de Aplicaciones Móviles
Estudiante: Brahian Andres Tenorio
"""

import sys
from fastapi.testclient import TestClient
from main import app, init_db

def run_tests():
    print("=" * 70)
    print("INICIANDO PRUEBAS DEL TALLER: AUTENTICACIÓN JWT Y PROTECCIÓN DE SERVICIOS")
    print("=" * 70)

    init_db()
    client = TestClient(app)

    # ------------------------------------------------------------------------
    # Escenario 1: Validación desde el backend - Acceso sin token (Rechazo 401)
    # ------------------------------------------------------------------------
    print("\n[ESCENARIO 1] Intentando acceder a servicios protegidos sin token...")
    res_no_token = client.get("/api/productos")
    assert res_no_token.status_code == 401, f"Error: Esperado 401, obtenido {res_no_token.status_code}"
    print(f" -> GET /api/productos: Código {res_no_token.status_code} - Acceso Denegado (Correcto)")
    print(f" -> Detalle del error: {res_no_token.json().get('detail')}")

    res_dash_no_token = client.get("/api/dashboard")
    assert res_dash_no_token.status_code == 401
    print(f" -> GET /api/dashboard: Código {res_dash_no_token.status_code} - Acceso Denegado (Correcto)")

    # ------------------------------------------------------------------------
    # Escenario 2: Credenciales incorrectas (Rechazo 401)
    # ------------------------------------------------------------------------
    print("\n[ESCENARIO 2] Intentando iniciar sesión con credenciales inválidas...")
    bad_payload = {
        "email": "brahian.tenorio@uceva.edu.co",
        "password": "clave_totalmente_erronea_999"
    }
    res_bad_login = client.post("/api/auth/login", json=bad_payload)
    assert res_bad_login.status_code == 401
    print(f" -> POST /api/auth/login (Clave incorrecta): Código {res_bad_login.status_code}")
    print(f" -> Detalle: {res_bad_login.json().get('detail')}")

    bad_user_payload = {
        "email": "no_existe_este_usuario@correo.com",
        "password": "password123"
    }
    res_nonexistent = client.post("/api/auth/login", json=bad_user_payload)
    assert res_nonexistent.status_code == 401
    print(f" -> POST /api/auth/login (Usuario inexistente): Código {res_nonexistent.status_code}")

    # ------------------------------------------------------------------------
    # Escenario 3: Token inválido o corrupto (Rechazo 401)
    # ------------------------------------------------------------------------
    print("\n[ESCENARIO 3] Petición con token Bearer alterado / no válido...")
    res_tampered = client.get(
        "/api/productos",
        headers={"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.token_corrupto.invalido"}
    )
    assert res_tampered.status_code == 401
    print(f" -> Código {res_tampered.status_code} - Detalle: {res_tampered.json().get('detail')}")

    # ------------------------------------------------------------------------
    # Escenario 4: Inicio de sesión correcto (200 OK y generación de JWT)
    # ------------------------------------------------------------------------
    print("\n[ESCENARIO 4] Iniciando sesión con credenciales válidas...")
    valid_payload = {
        "email": "brahian.tenorio@uceva.edu.co",
        "password": "admin123"
    }
    res_login = client.post("/api/auth/login", json=valid_payload)
    assert res_login.status_code == 200, f"Error: Esperado 200, obtenido {res_login.status_code}"
    login_data = res_login.json()
    token = login_data["access_token"]
    user_info = login_data["user"]
    assert token is not None and len(token) > 20
    print(f" -> Login Exitoso para: {user_info['nombre']} ({user_info['email']})")
    print(f" -> Token JWT Generado: {token[:25]}... (Longitud: {len(token)} caracteres)")

    auth_headers = {"Authorization": f"Bearer {token}"}

    # ------------------------------------------------------------------------
    # Escenario 5: Verificación de sesión mediante /api/auth/verify y /api/auth/me
    # ------------------------------------------------------------------------
    print("\n[ESCENARIO 5] Verificando token JWT y perfil de usuario autenticado...")
    res_verify = client.get("/api/auth/verify", headers=auth_headers)
    assert res_verify.status_code == 200
    print(f" -> GET /api/auth/verify: {res_verify.json()}")

    res_me = client.get("/api/auth/me", headers=auth_headers)
    assert res_me.status_code == 200
    print(f" -> GET /api/auth/me: {res_me.json()}")

    # ------------------------------------------------------------------------
    # Escenario 6: Consumo de servicios protegidos (CRUD con Bearer Token)
    # ------------------------------------------------------------------------
    print("\n[ESCENARIO 6] Consumo de operaciones protegidas (CRUD + Dashboard)...")
    
    # Dashboard protegido
    res_dash = client.get("/api/dashboard", headers=auth_headers)
    assert res_dash.status_code == 200
    print(f" -> GET /api/dashboard: {res_dash.json()}")

    # Listar productos protegidos
    res_list = client.get("/api/productos", headers=auth_headers)
    assert res_list.status_code == 200
    productos = res_list.json()
    print(f" -> GET /api/productos: {len(productos)} productos listados con token")

    # Crear producto protegido (POST)
    nuevo_producto = {
        "nombre": "Teclado Ergonomico Bluetooth Test",
        "codigo": "TEST-JWT-999",
        "descripcion": "Producto creado durante prueba automatizada con JWT",
        "precio": 250000.0,
        "cantidad": 10,
        "categoria": "Accesorios"
    }
    res_create = client.post("/api/productos", json=nuevo_producto, headers=auth_headers)
    assert res_create.status_code == 201, f"Error al crear: {res_create.json()}"
    prod_creado = res_create.json()
    nuevo_id = prod_creado["id"]
    print(f" -> POST /api/productos: Producto #{nuevo_id} creado con éxito")

    # Actualizar producto protegido (PUT)
    update_data = {
        "precio": 240000.0,
        "cantidad": 15
    }
    res_update = client.put(f"/api/productos/{nuevo_id}", json=update_data, headers=auth_headers)
    assert res_update.status_code == 200
    print(f" -> PUT /api/productos/{nuevo_id}: Producto actualizado (Precio: {res_update.json()['precio']})")

    # Eliminar producto protegido (DELETE)
    res_delete = client.delete(f"/api/productos/{nuevo_id}", headers=auth_headers)
    assert res_delete.status_code == 200
    print(f" -> DELETE /api/productos/{nuevo_id}: {res_delete.json().get('mensaje')}")

    print("\n" + "=" * 70)
    print("¡TODAS LAS PRUEBAS OBLIGATORIAS PASARON CON ÉXITO AL 100%!")
    print("=" * 70)

if __name__ == "__main__":
    run_tests()
