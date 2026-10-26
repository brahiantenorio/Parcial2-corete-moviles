import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventario_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.inventory, size: 24),
            SizedBox(width: 8),
            Text(
              'Gestión de Inventario',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar datos',
            onPressed: () {
              context.read<InventarioProvider>().inicializar();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<InventarioProvider>().inicializar();
        },
        child: provider.isLoading && provider.productos.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.errorMessage != null && provider.productos.isEmpty
                ? EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Error de conexión',
                    message: provider.errorMessage!,
                    buttonText: 'Reintentar conexión',
                    onButtonPressed: () {
                      context.read<InventarioProvider>().inicializar();
                    },
                    iconColor: Colors.redAccent,
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado de bienvenida
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Panel de Control Principal',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Métricas en tiempo real sincronizadas con SQLite REST API',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Sección: Métricas del Inventario
                        const Text(
                          'Métricas del Inventario',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        // Tarjeta 1: Total de productos registrados
                        StatCard(
                          title: 'Total de Productos Registrados',
                          value: '${provider.totalProductosRegistrados}',
                          subtitle: 'Referencias únicas en la base de datos',
                          icon: Icons.category_rounded,
                          gradientColors: const [Color(0xFF1E88E5), Color(0xFF1565C0)],
                          onTap: () => context.go('/productos'),
                        ),
                        const SizedBox(height: 10),

                        // Tarjeta 2: Total de unidades disponibles
                        StatCard(
                          title: 'Total de Unidades Disponibles',
                          value: '${provider.totalUnidadesInventario} uds.',
                          subtitle: 'Stock físico acumulado en almacén',
                          icon: Icons.inventory_2_rounded,
                          gradientColors: const [Color(0xFF00897B), Color(0xFF00695C)],
                          onTap: () => context.go('/productos'),
                        ),
                        const SizedBox(height: 10),

                        // Tarjeta 3: Valor económico total del inventario
                        StatCard(
                          title: 'Valor Económico del Inventario',
                          value: provider.stats?.valorTotalFormateado ?? '\$ 0',
                          subtitle: 'Cálculo dinámico: ∑ (precio unitario × cantidad)',
                          icon: Icons.monetization_on_rounded,
                          gradientColors: const [Color(0xFF5E35B1), Color(0xFF4527A0)],
                          onTap: () => context.go('/productos'),
                        ),
                        const SizedBox(height: 22),

                        // Accesos directos a la gestión de productos
                        const Text(
                          'Acceso Rápido a Funcionalidades',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.list_alt_rounded),
                                label: const Text('Ver Productos'),
                                onPressed: () => context.go('/productos'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Nuevo Producto'),
                                onPressed: () => context.go('/productos/nuevo'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Alerta de productos con stock bajo (si los hay)
                        Builder(
                          builder: (context) {
                            final bajos = provider.productos.where((p) => p.cantidad <= 5).toList();
                            if (bajos.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Alerta: ${bajos.length} Producto(s) con Stock Bajo (≤ 5 uds.)',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...bajos.take(3).map(
                                  (p) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.inventory_outlined, color: Colors.orange),
                                      title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${p.codigo} • ${p.categoria}'),
                                      trailing: Text(
                                        '${p.cantidad} uds.',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      onTap: () => context.go('/productos/${p.id}'),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }
}
