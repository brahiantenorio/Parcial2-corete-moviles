import 'package:intl/intl.dart';

class Producto {
  final int? id;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final double precio;
  final int cantidad;
  final String categoria;

  Producto({
    this.id,
    required this.nombre,
    required this.codigo,
    this.descripcion,
    required this.precio,
    required this.cantidad,
    required this.categoria,
  });

  /// Calcula el valor económico total en stock para este producto (precio * cantidad)
  double get valorTotalStock => precio * cantidad;

  /// Retorna el precio unitario formateado en pesos / moneda
  String get precioFormateado {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(precio);
  }

  /// Retorna el valor total de inventario formateado
  String get valorTotalFormateado {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(valorTotalStock);
  }

  /// Construye una instancia a partir del mapa JSON retornado por la API
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()),
      nombre: json['nombre']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      precio: (json['precio'] is num) ? (json['precio'] as num).toDouble() : (double.tryParse(json['precio'].toString()) ?? 0.0),
      cantidad: (json['cantidad'] is num) ? (json['cantidad'] as num).toInt() : (int.tryParse(json['cantidad'].toString()) ?? 0),
      categoria: json['categoria']?.toString() ?? 'General',
    );
  }

  /// Serializa a JSON para peticiones POST o PUT hacia la API
  Map<String, dynamic> toJson({bool includeId = false}) {
    final Map<String, dynamic> data = {
      'nombre': nombre.trim(),
      'codigo': codigo.trim().toUpperCase(),
      'descripcion': descripcion?.trim().isNotEmpty == true ? descripcion!.trim() : null,
      'precio': precio,
      'cantidad': cantidad,
      'categoria': categoria.trim(),
    };

    if (includeId && id != null) {
      data['id'] = id;
    }

    return data;
  }

  /// Permite clonar y modificar propiedades
  Producto copyWith({
    int? id,
    String? nombre,
    String? codigo,
    String? descripcion,
    double? precio,
    int? cantidad,
    String? categoria,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
      categoria: categoria ?? this.categoria,
    );
  }
}
