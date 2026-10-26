from pydantic import BaseModel, Field
from typing import Optional

class ProductoBase(BaseModel):
    nombre: str = Field(..., min_length=2, max_length=150, description="Nombre del producto")
    codigo: str = Field(..., min_length=2, max_length=50, description="Código único del producto")
    descripcion: Optional[str] = Field(None, max_length=500, description="Descripción detallada del producto (opcional)")
    precio: float = Field(..., gt=0, description="Precio unitario del producto (debe ser mayor a 0)")
    cantidad: int = Field(..., ge=0, description="Unidades disponibles en inventario (mayor o igual a 0)")
    categoria: str = Field(..., min_length=2, max_length=100, description="Categoría a la que pertenece el producto")

class ProductoCreate(ProductoBase):
    pass

class ProductoUpdate(BaseModel):
    nombre: Optional[str] = Field(None, min_length=2, max_length=150)
    codigo: Optional[str] = Field(None, min_length=2, max_length=50)
    descripcion: Optional[str] = Field(None, max_length=500)
    precio: Optional[float] = Field(None, gt=0)
    cantidad: Optional[int] = Field(None, ge=0)
    categoria: Optional[str] = Field(None, min_length=2, max_length=100)

class ProductoResponse(BaseModel):
    id: int
    nombre: str
    codigo: str
    descripcion: Optional[str] = None
    precio: float
    cantidad: int
    categoria: str

    class Config:
        from_attributes = True

class DashboardStats(BaseModel):
    total_productos: int
    total_unidades: int
    valor_total_inventario: float

class MensajeResponse(BaseModel):
    mensaje: str
    producto: Optional[ProductoResponse] = None
