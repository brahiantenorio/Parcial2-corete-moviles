import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventario_provider.dart';
import '../models/producto.dart';
import '../widgets/empty_state.dart';

class ProductoDetailScreen extends StatefulWidget {
  final int productoId;

  const ProductoDetailScreen({super.key, required this.productoId});

  @override
  State<ProductoDetailScreen> createState() => _ProductoDetailScreenState();
}

class _ProductoDetailScreenState extends State<ProductoDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventarioProvider>().cargarDetalle(widget.productoId);
    });
  }

  void _confirmarEliminar(Producto producto) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
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
          '¿Desea eliminar definitivamente el producto "${producto.nombre}"?\n\nEsta acción borrará el registro de la base de datos.',
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
              final ok = await provider.eliminarProducto(producto.id!);

              if (ok) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Producto "${producto.nombre}" eliminado con éxito.'),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
                router.go('/productos');
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Error al eliminar el producto.'),
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
    final producto = provider.selectedProducto;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Producto', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (producto != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar producto',
              onPressed: () => context.go('/productos/${producto.id}/editar'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Eliminar producto',
              onPressed: () => _confirmarEliminar(producto),
            ),
          ],
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Error al consultar producto',
                  message: provider.errorMessage!,
                  buttonText: 'Volver al catálogo',
                  onButtonPressed: () => context.go('/productos'),
                  iconColor: Colors.redAccent,
                )
              : producto == null
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Producto no encontrado',
                      message: 'No se encontró el producto con identificador #${widget.productoId}',
                      buttonText: 'Volver a productos',
                      onButtonPressed: () => context.go('/productos'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card principal de presentación
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Chip(
                                        label: Text(
                                          producto.categoria,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'ID #${producto.id} • ${producto.codigo}',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    producto.nombre,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 12),

                                  // Métricas clave del producto
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDetailTile(
                                          context,
                                          icon: Icons.attach_money_rounded,
                                          title: 'Precio Unitario',
                                          value: producto.precioFormateado,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildDetailTile(
                                          context,
                                          icon: Icons.inventory_2_rounded,
                                          title: 'Stock Disponible',
                                          value: '${producto.cantidad} unidades',
                                          color: producto.cantidad <= 5 ? Colors.orange : Colors.teal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDetailTile(
                                    context,
                                    icon: Icons.account_balance_wallet_rounded,
                                    title: 'Valor Total en Inventario (Precio × Cantidad)',
                                    value: producto.valorTotalFormateado,
                                    color: Colors.deepPurple,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Card de Descripción
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.description_outlined, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Descripción del Producto',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    producto.descripcion != null && producto.descripcion!.isNotEmpty
                                        ? producto.descripcion!
                                        : 'Sin descripción detallada registrada.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: producto.descripcion != null && producto.descripcion!.isNotEmpty
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade500,
                                      fontStyle: producto.descripcion != null && producto.descripcion!.isNotEmpty
                                          ? FontStyle.normal
                                          : FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Botones de acción inferior
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Editar Producto'),
                                  onPressed: () => context.go('/productos/${producto.id}/editar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Eliminar'),
                                  onPressed: () => _confirmarEliminar(producto),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
