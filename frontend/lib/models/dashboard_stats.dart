import 'package:intl/intl.dart';

class DashboardStats {
  final int totalProductos;
  final int totalUnidades;
  final double valorTotalInventario;

  DashboardStats({
    required this.totalProductos,
    required this.totalUnidades,
    required this.valorTotalInventario,
  });

  String get valorTotalFormateado {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(valorTotalInventario);
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalProductos: (json['total_productos'] is num) ? (json['total_productos'] as num).toInt() : 0,
      totalUnidades: (json['total_unidades'] is num) ? (json['total_unidades'] as num).toInt() : 0,
      valorTotalInventario: (json['valor_total_inventario'] is num) ? (json['valor_total_inventario'] as num).toDouble() : 0.0,
    );
  }

  /// Permite calcular las métricas directamente a partir de la lista de productos
  factory DashboardStats.fromProductos(List<dynamic> productos) {
    int count = productos.length;
    int unidades = 0;
    double valor = 0.0;

    for (var p in productos) {
      unidades += (p.cantidad as int);
      valor += (p.precio as double) * (p.cantidad as int);
    }

    return DashboardStats(
      totalProductos: count,
      totalUnidades: unidades,
      valorTotalInventario: valor,
    );
  }
}
