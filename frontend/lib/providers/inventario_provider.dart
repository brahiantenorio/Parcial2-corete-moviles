import 'package:flutter/foundation.dart';
import '../models/producto.dart';
import '../models/dashboard_stats.dart';
import '../services/producto_service.dart';

/// Provider que administra el estado global del inventario y orquesta las operaciones con la API
class InventarioProvider extends ChangeNotifier {
  final ProductoService _service;

  InventarioProvider({ProductoService? service}) : _service = service ?? ProductoService();

  List<Producto> _productos = [];
  DashboardStats? _stats;
  Producto? _selectedProducto;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategoria = 'Todos';

  // Getters
  List<Producto> get productos => _productos;
  DashboardStats? get stats => _stats;
  Producto? get selectedProducto => _selectedProducto;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategoria => _selectedCategoria;

  /// Indicadores calculados dinámicamente sobre la lista real de productos
  int get totalProductosRegistrados => _productos.length;
  int get totalUnidadesInventario => _productos.fold(0, (sum, p) => sum + p.cantidad);
  double get valorEconomicoTotalInventario => _productos.fold(0.0, (sum, p) => sum + p.valorTotalStock);

  /// Obtiene la lista única de categorías para los filtros
  List<String> get categoriasDisponibles {
    final set = <String>{'Todos'};
    for (var p in _productos) {
      if (p.categoria.isNotEmpty) {
        set.add(p.categoria);
      }
    }
    return set.toList();
  }

  /// Carga inicial de datos para la aplicación
  Future<void> inicializar() async {
    await cargarProductos();
    await cargarStats();
  }

  /// Consulta la lista de productos desde la API REST
  Future<void> cargarProductos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _productos = await _service.getProductos(
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoria: _selectedCategoria != 'Todos' ? _selectedCategoria : null,
      );
      // Recalcular estadísticas con la información fresca
      _recalcularStatsLocales();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga las estadísticas desde el endpoint dedicado del backend
  Future<void> cargarStats() async {
    try {
      _stats = await _service.getDashboardStats();
      notifyListeners();
    } catch (_) {
      // Si falla el endpoint de estadísticas, usamos el cálculo local de la lista
      _recalcularStatsLocales();
    }
  }

  void _recalcularStatsLocales() {
    _stats = DashboardStats.fromProductos(_productos);
  }

  /// Consulta el detalle completo de un producto
  Future<void> cargarDetalle(int id) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedProducto = null;
    notifyListeners();

    try {
      _selectedProducto = await _service.getProductoById(id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registra un nuevo producto (POST) o actualiza uno existente (PUT)
  Future<bool> guardarProducto(Producto producto) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (producto.id != null) {
        // Operación PUT
        final actualizado = await _service.updateProducto(producto.id!, producto);
        final index = _productos.indexWhere((p) => p.id == actualizado.id);
        if (index != -1) {
          _productos[index] = actualizado;
        } else {
          _productos.insert(0, actualizado);
        }
        _selectedProducto = actualizado;
      } else {
        // Operación POST
        final nuevo = await _service.createProducto(producto);
        _productos.insert(0, nuevo);
        _selectedProducto = nuevo;
      }

      _recalcularStatsLocales();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Elimina un producto por su ID (DELETE)
  Future<bool> eliminarProducto(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _service.deleteProducto(id);
      if (ok) {
        _productos.removeWhere((p) => p.id == id);
        if (_selectedProducto?.id == id) {
          _selectedProducto = null;
        }
        _recalcularStatsLocales();
      }
      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualiza el filtro de búsqueda
  void setSearchQuery(String query) {
    _searchQuery = query;
    cargarProductos();
  }

  /// Actualiza el filtro de categoría
  void setCategoria(String categoria) {
    _selectedCategoria = categoria;
    cargarProductos();
  }

  /// Restablece los filtros de búsqueda
  void limpiarFiltros() {
    _searchQuery = '';
    _selectedCategoria = 'Todos';
    cargarProductos();
  }

  /// Limpia los mensajes de error
  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }
}
