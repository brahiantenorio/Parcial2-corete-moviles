import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/producto.dart';
import '../models/dashboard_stats.dart';
import 'session_storage_service.dart';

/// Servicio responsable de las operaciones CRUD y consultas protegidas con la API REST utilizando Dio
class ProductoService {
  final Dio _dio;
  final SessionStorageService _sessionStorage;
  final VoidCallback? onUnauthorized;

  ProductoService({
    Dio? dio,
    SessionStorageService? sessionStorage,
    this.onUnauthorized,
  })  : _sessionStorage = sessionStorage ?? SessionStorageService(),
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    // Configuración de interceptores de Dio para inyectar automáticamente el Bearer token
    // y capturar respuestas 401 de sesión expirada
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _sessionStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException err, handler) {
          if (err.response?.statusCode == 401) {
            debugPrint('[DIO] 401 Unauthorized recibido: Notificando expiración de sesión.');
            onUnauthorized?.call();
          }
          return handler.next(err);
        },
      ),
    );
  }

  /// Obtiene la lista completa de productos desde GET /api/productos (Protegido con JWT)
  Future<List<Producto>> getProductos({String? query, String? categoria}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (query != null && query.trim().isNotEmpty) {
        queryParams['q'] = query.trim();
      }
      if (categoria != null && categoria.trim().isNotEmpty && categoria != 'Todos') {
        queryParams['categoria'] = categoria.trim();
      }

      final response = await _dio.get(
        ApiConfig.productos,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data as List;
        return list.map((item) => Producto.fromJson(item as Map<String, dynamic>)).toList();
      }

      return [];
    } on DioException catch (e) {
      throw _handleDioError(e, 'obtener los productos');
    } catch (e) {
      throw 'Error inesperado al cargar productos: $e';
    }
  }

  /// Consulta el detalle de un producto específico mediante GET /api/productos/{id} (Protegido con JWT)
  Future<Producto> getProductoById(int id) async {
    try {
      final response = await _dio.get(ApiConfig.productoById(id));

      if (response.statusCode == 200 && response.data != null) {
        return Producto.fromJson(response.data as Map<String, dynamic>);
      }

      throw 'No se pudo obtener la información del producto';
    } on DioException catch (e) {
      throw _handleDioError(e, 'consultar el producto #$id');
    } catch (e) {
      throw 'Error inesperado: $e';
    }
  }

  /// Registra un nuevo producto mediante POST /api/productos (Protegido con JWT)
  Future<Producto> createProducto(Producto producto) async {
    try {
      final response = await _dio.post(
        ApiConfig.productos,
        data: producto.toJson(includeId: false),
      );

      if (response.statusCode == 201 && response.data != null) {
        return Producto.fromJson(response.data as Map<String, dynamic>);
      }

      throw 'Respuesta inesperada del servidor al crear producto';
    } on DioException catch (e) {
      throw _handleDioError(e, 'registrar el producto');
    } catch (e) {
      throw 'Error inesperado al guardar el producto: $e';
    }
  }

  /// Actualiza un producto existente mediante PUT /api/productos/{id} (Protegido con JWT)
  Future<Producto> updateProducto(int id, Producto producto) async {
    try {
      final response = await _dio.put(
        ApiConfig.productoById(id),
        data: producto.toJson(includeId: false),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Producto.fromJson(response.data as Map<String, dynamic>);
      }

      throw 'Respuesta inesperada al actualizar el producto';
    } on DioException catch (e) {
      throw _handleDioError(e, 'actualizar el producto #$id');
    } catch (e) {
      throw 'Error inesperado al actualizar: $e';
    }
  }

  /// Elimina un producto de la base de datos mediante DELETE /api/productos/{id} (Protegido con JWT)
  Future<bool> deleteProducto(int id) async {
    try {
      final response = await _dio.delete(ApiConfig.productoById(id));

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      throw _handleDioError(e, 'eliminar el producto #$id');
    } catch (e) {
      throw 'Error inesperado al eliminar: $e';
    }
  }

  /// Obtiene las estadísticas consolidadas del Dashboard desde GET /api/dashboard (Protegido con JWT)
  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _dio.get(ApiConfig.dashboard);

      if (response.statusCode == 200 && response.data != null) {
        return DashboardStats.fromJson(response.data as Map<String, dynamic>);
      }

      throw 'No se pudieron calcular las estadísticas del inventario';
    } on DioException catch (e) {
      throw _handleDioError(e, 'cargar estadísticas del dashboard');
    } catch (e) {
      throw 'Error inesperado al obtener métricas: $e';
    }
  }

  /// Traduce las excepciones de Dio a mensajes claros en español
  String _handleDioError(DioException e, String accion) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tiempo de espera agotado al $accion en ${ApiConfig.baseUrl}. Asegúrese de que el servidor backend esté corriendo.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar con el servidor (${ApiConfig.baseUrl}). Verifique que el backend FastAPI esté ejecutándose en el puerto 8000.';
    }

    if (e.response != null) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      String? serverDetail;
      if (data is Map && data.containsKey('detail')) {
        if (data['detail'] is String) {
          serverDetail = data['detail'];
        } else if (data['detail'] is List) {
          final list = data['detail'] as List;
          serverDetail = list.map((item) => item['msg'] ?? item.toString()).join(', ');
        }
      }

      if (serverDetail != null && serverDetail.isNotEmpty) {
        return serverDetail;
      }

      switch (status) {
        case 400:
          return 'Petición inválida: Verifique que el código sea único y los datos correctos.';
        case 401:
          return 'Acceso no autorizado (401): Su sesión no es válida o ha expirado. Por favor inicie sesión nuevamente.';
        case 403:
          return 'Acceso denegado (403): No tiene permisos suficientes para realizar esta acción.';
        case 404:
          return 'El recurso solicitado no fue encontrado en el servidor.';
        case 422:
          return 'Error de validación: Datos enviados con formato incorrecto.';
        case 500:
          return 'Error interno en el servidor backend al $accion.';
        default:
          return 'El servidor respondió con código $status al $accion.';
      }
    }

    return 'Error de red o comunicación al $accion: ${e.message}';
  }
}
