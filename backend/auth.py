import os
import hashlib
import secrets
from datetime import datetime, timezone, timedelta
from typing import Optional, Dict, Any
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from database import get_db_connection

# Clave secreta para firmar los tokens JWT (mínimo 32 bytes para cumplimiento RFC 7518)
SECRET_KEY = os.getenv(
    "JWT_SECRET_KEY",
    "b3a886f4a2176b9dfa5cf8a7ec263702e88a038bf3471dfc8861cf8fcf6eb722a492f16e8b4e107b71f98d4e"
)
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_HOURS = 24

security_scheme = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    """Genera un hash seguro utilizando PBKDF2-HMAC-SHA256 con sal aleatoria."""
    salt = secrets.token_hex(16)
    pwd_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        iterations=100000
    ).hex()
    return f"{salt}${pwd_hash}"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifica si la contraseña en texto plano coincide con el hash almacenado."""
    try:
        if not hashed_password or "$" not in hashed_password:
            return False
        salt, stored_hash = hashed_password.split("$", 1)
        calc_hash = hashlib.pbkdf2_hmac(
            "sha256",
            plain_password.encode("utf-8"),
            salt.encode("utf-8"),
            iterations=100000
        ).hex()
        return secrets.compare_digest(calc_hash, stored_hash)
    except Exception:
        return False


def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """Crea un JSON Web Token (JWT) firmado con algoritmo HS256 y tiempo de expiración."""
    to_encode = data.copy()
    now = datetime.now(timezone.utc)
    expire = now + (expires_delta or timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS))
    to_encode.update({
        "exp": expire,
        "iat": now,
        "nbf": now,
    })
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token(token: str) -> Dict[str, Any]:
    """Decodifica y valida la firma y expiración de un token JWT."""
    return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])


def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme)
) -> Dict[str, Any]:
    """
    Dependencia de FastAPI para proteger endpoints.
    Valida el encabezado 'Authorization: Bearer <token>' y comprueba que el usuario
    exista y esté activo en la base de datos.
    """
    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Acceso no autorizado: No se proporcionó el token de autenticación en el encabezado Authorization.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials.strip()

    try:
        payload = decode_access_token(token)
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token de autenticación inválido: Falta el identificador de usuario (sub).",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="La sesión ha expirado. Por favor, vuelva a iniciar sesión.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de autenticación inválido o alterado.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Verificar existencia y estado del usuario en la base de datos SQLite
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT id, nombre, email, rol, activo FROM usuarios WHERE id = ?",
        (int(user_id),)
    )
    user_row = cursor.fetchone()
    conn.close()

    if not user_row:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="El usuario asociado al token no existe en el sistema.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user_row["activo"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="La cuenta de usuario se encuentra inactiva.",
        )

    return dict(user_row)
