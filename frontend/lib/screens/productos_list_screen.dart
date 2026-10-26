import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventario_provider.dart';
import '../widgets/producto_card.dart';
import '../widgets/empty_state.dart';
import '../models/producto.dart';

class ProductosListScreen extends StatefulWidget {
  const ProductosListScreen({super.key});

  @override
  State<ProductosListScreen> createState() => _ProductosListScreenState();
}

class _ProductosListScreenState extends State<ProductosListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _confirmarEliminar(Producto producto) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = context.read<InventarioProvider>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar Eliminación'),
          ],
        ),
        content: Text(
          '¿Está seguro de que desea eliminar el producto "${producto.nombre}" (${producto.codigo})?\n\nEsta acción no se puede deshacer en la base de datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await provider.eliminarProducto(producto.id!);

              if (success) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Producto "${producto.nombre}" eliminado correctamente.'),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Error al eliminar producto.'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar lista',
            onPressed: () => provider.cargarProductos(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/productos/nuevo'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              onChanged: (val) {
                provider.setSearchQuery(val);
                setState(() {});
              },
            ),
          ),

          // Filtro horizontal de categorías
          if (provider.categoriasDisponibles.length > 1)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                itemCount: provider.categoriasDisponibles.length,
                itemBuilder: (context, index) {
                  final cat = provider.categoriasDisponibles[index];
                  final isSelected = provider.selectedCategoria == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat),
                      onSelected: (_) => provider.setCategoria(cat),
                    ),
                  );
                },
              ),
            ),

          // Total de resultados encontrados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${provider.productos.length} producto(s) encontrado(s)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (provider.searchQuery.isNotEmpty || provider.selectedCategoria != 'Todos')
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.filter_alt_off, size: 16),
                    label: const Text('Limpiar filtros', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      _searchCtrl.clear();
                      provider.limpiarFiltros();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),

          // Lista de productos o estados (cargando, error, vacío)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await provider.cargarProductos();
              },
              child: provider.isLoading && provider.productos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null && provider.productos.isEmpty
                      ? EmptyState(
                          icon: Icons.error_outline_rounded,
                          title: 'Error al cargar productos',
                          message: provider.errorMessage!,
                          buttonText: 'Reintentar',
                          onButtonPressed: () => provider.cargarProductos(),
                          iconColor: Colors.redAccent,
                        )
                      : provider.productos.isEmpty
                          ? EmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: 'No hay productos disponibles',
                              message: provider.searchQuery.isNotEmpty
                                  ? 'No se encontraron resultados para "${provider.searchQuery}".'
                                  : 'El inventario está actualmente vacío. Comienza registrando tu primer producto.',
                              buttonText: 'Registrar Producto',
                              onButtonPressed: () => context.go('/productos/nuevo'),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: provider.productos.length,
                              itemBuilder: (context, index) {
                                final producto = provider.productos[index];
                                return ProductoCard(
                                  producto: producto,
                                  onTap: () => context.go('/productos/${producto.id}'),
                                  onEdit: () => context.go('/productos/${producto.id}/editar'),
                                  onDelete: () => _confirmarEliminar(producto),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
