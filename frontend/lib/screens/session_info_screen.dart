import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SessionInfoScreen extends StatelessWidget {
  const SessionInfoScreen({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Cerrar Sesión'),
          ],
        ),
        content: const Text(
          '¿Está seguro de que desea cerrar la sesión actual?\n\n'
          'Se eliminarán de forma segura el token JWT de flutter_secure_storage y los datos de sesión en shared_preferences.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Información de Sesión'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta Principal de Perfil
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            user?.nombre.isNotEmpty == true
                                ? user!.nombre.substring(0, 1).toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.nombre ?? 'Sin usuario autenticado',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'correo@desconocido.com',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Chip de estado de autenticación
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isAuthenticated ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isAuthenticated ? Colors.green.shade400 : Colors.red.shade400,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAuthenticated ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                size: 18,
                                color: isAuthenticated ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isAuthenticated ? 'Estado: Sesión Activa' : 'Estado: Sin Sesión',
                                style: TextStyle(
                                  color: isAuthenticated ? Colors.green.shade800 : Colors.red.shade800,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tarjeta de Almacenamiento Seguro (flutter_secure_storage)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security_rounded, color: theme.colorScheme.primary),
                            const SizedBox(width: 10),
                            Text(
                              'Almacenamiento Seguro (JWT)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          icon: Icons.vpn_key_rounded,
                          label: 'Indicador del Token:',
                          value: authProvider.tokenPreview,
                          isCode: true,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.storage_rounded,
                          label: 'Mecanismo de Guardado:',
                          value: 'flutter_secure_storage (Cifrado seguro del SO)',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.shield_outlined,
                          label: 'Algoritmo de Firma:',
                          value: 'HMAC-SHA256 (HS256)',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.http_rounded,
                          label: 'Encabezado HTTP:',
                          value: 'Authorization: Bearer <token>',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Colors.amber.shade900),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Por seguridad, el token JWT nunca se almacena en texto plano ni se muestra completo en pantalla.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tarjeta de Almacenamiento Local (shared_preferences)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bookmark_outline_rounded, color: Colors.teal),
                            const SizedBox(width: 10),
                            Text(
                              'Datos en shared_preferences (No sensibles)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          icon: Icons.person_outline,
                          label: 'Nombre de usuario:',
                          value: user?.nombre ?? 'No registrado',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Correo electrónico:',
                          value: user?.email ?? 'No registrado',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'Rol del usuario:',
                          value: user?.rol.toUpperCase() ?? 'USUARIO',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón de Cerrar Sesión
                FilledButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Cerrar Sesión Activa',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isCode = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontFamily: isCode ? 'monospace' : null,
              color: isCode ? Colors.indigo.shade800 : Colors.black87,
              fontWeight: isCode ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
