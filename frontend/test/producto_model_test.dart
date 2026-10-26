import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/producto.dart';
import 'package:frontend/models/dashboard_stats.dart';

void main() {
  group('Pruebas Unitarias del Modelo Producto', () {
    test('Debe deserializar correctamente un mapa JSON a Producto', () {
      final json = {
        'id': 1,
        'nombre': 'Laptop HP ProBook',
        'codigo': 'HP-101',
        'descripcion': 'Portátil Intel Core i5',
        'precio': 2500000.0,
        'cantidad': 8,
        'categoria': 'Tecnología',
      };

      final producto = Producto.fromJson(json);

      expect(producto.id, equals(1));
      expect(producto.nombre, equals('Laptop HP ProBook'));
      expect(producto.codigo, equals('HP-101'));
      expect(producto.precio, equals(2500000.0));
      expect(producto.cantidad, equals(8));
      expect(producto.categoria, equals('Tecnología'));
      expect(producto.valorTotalStock, equals(20000000.0));
    });

    test('Debe serializar un Producto a JSON correctamente para POST', () {
      final producto = Producto(
        nombre: 'Mouse Gamer RGB',
        codigo: 'MS-202',
        descripcion: 'Mouse óptico 6400 DPI',
        precio: 95000.0,
        cantidad: 15,
        categoria: 'Accesorios',
      );

      final json = producto.toJson(includeId: false);

      expect(json.containsKey('id'), isFalse);
      expect(json['nombre'], equals('Mouse Gamer RGB'));
      expect(json['codigo'], equals('MS-202'));
      expect(json['precio'], equals(95000.0));
      expect(json['cantidad'], equals(15));
      expect(json['categoria'], equals('Accesorios'));
    });
  });

  group('Pruebas Unitarias de DashboardStats', () {
    test('Debe calcular las métricas consolidando una lista de productos', () {
      final productos = [
        Producto(nombre: 'A', codigo: 'A-1', precio: 1000.0, cantidad: 5, categoria: 'Cat1'),
        Producto(nombre: 'B', codigo: 'B-2', precio: 2000.0, cantidad: 10, categoria: 'Cat2'),
      ];

      final stats = DashboardStats.fromProductos(productos);

      expect(stats.totalProductos, equals(2));
      expect(stats.totalUnidades, equals(15));
      expect(stats.valorTotalInventario, equals(25000.0)); // (1000*5) + (2000*10) = 5000 + 20000 = 25000
    });
  });
}
