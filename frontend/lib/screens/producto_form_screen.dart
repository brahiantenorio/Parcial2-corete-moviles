import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventario_provider.dart';
import '../models/producto.dart';

class ProductoFormScreen extends StatefulWidget {
  final int? productoId;

  const ProductoFormScreen({super.key, this.productoId});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreCtrl;
  late TextEditingController _codigoCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _precioCtrl;
  late TextEditingController _cantidadCtrl;
  late TextEditingController _categoriaCtrl;

  bool _isInit = false;
  String? _selectedCategoryDropdown;

  final List<String> _categoriasSugeridas = [
    'Tecnología',
    'Accesorios',
    'Monitores',
    'Audio',
    'Oficina',
    'Almacenamiento',
    'Componentes',
    'Mobiliario',
    'Video',
    'Otra...',
  ];

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _codigoCtrl = TextEditingController();
    _descripcionCtrl = TextEditingController();
    _precioCtrl = TextEditingController();
    _cantidadCtrl = TextEditingController();
    _categoriaCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      if (widget.productoId != null) {
        // Modo Edición: cargar datos existentes
        final provider = context.read<InventarioProvider>();
        final p = provider.selectedProducto != null && provider.selectedProducto!.id == widget.productoId
            ? provider.selectedProducto
            : provider.productos.cast<Producto?>().firstWhere(
                  (item) => item?.id == widget.productoId,
                  orElse: () => null,
                );

        if (p != null) {
          _cargarDatosEnFormulario(p);
        } else {
          // Consultar desde API
          provider.cargarDetalle(widget.productoId!).then((_) {
            if (mounted && provider.selectedProducto != null) {
              _cargarDatosEnFormulario(provider.selectedProducto!);
            }
          });
        }
      }
      _isInit = true;
    }
  }

  void _cargarDatosEnFormulario(Producto p) {
    _nombreCtrl.text = p.nombre;
    _codigoCtrl.text = p.codigo;
    _descripcionCtrl.text = p.descripcion ?? '';
    _precioCtrl.text = p.precio % 1 == 0 ? p.precio.toInt().toString() : p.precio.toString();
    _cantidadCtrl.text = p.cantidad.toString();
    _categoriaCtrl.text = p.categoria;

    if (_categoriasSugeridas.contains(p.categoria)) {
      _selectedCategoryDropdown = p.categoria;
    } else {
      _selectedCategoryDropdown = 'Otra...';
    }
    setState(() {});
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    _cantidadCtrl.dispose();
    _categoriaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double? precio = double.tryParse(_precioCtrl.text.trim().replaceAll(',', '.'));
    final int? cantidad = int.tryParse(_cantidadCtrl.text.trim());

    if (precio == null || precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El precio debe ser un número decimal mayor a 0.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (cantidad == null || cantidad < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cantidad debe ser un número entero mayor o igual a 0.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final producto = Producto(
      id: widget.productoId,
      nombre: _nombreCtrl.text.trim(),
      codigo: _codigoCtrl.text.trim().toUpperCase(),
      descripcion: _descripcionCtrl.text.trim().isNotEmpty ? _descripcionCtrl.text.trim() : null,
      precio: precio,
      cantidad: cantidad,
      categoria: _categoriaCtrl.text.trim(),
    );

    final provider = context.read<InventarioProvider>();
    final ok = await provider.guardarProducto(producto);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.productoId != null
                ? 'Producto "${producto.nombre}" actualizado exitosamente.'
                : 'Producto "${producto.nombre}" registrado exitosamente en la base de datos.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      context.go('/productos');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al guardar el producto.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productoId != null;
    final isSaving = context.watch<InventarioProvider>().isSaving;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Producto (#${widget.productoId})' : 'Registrar Nuevo Producto',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner informativo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEditing
                            ? 'Modifique los campos necesarios y guarde los cambios en la API REST.'
                            : 'Complete el formulario para almacenar un nuevo producto en la base de datos.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Campo: Nombre del producto
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Producto *',
                  hintText: 'Ej. Laptop Lenovo ThinkPad',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El nombre del producto es obligatorio.';
                  }
                  if (val.trim().length < 2) {
                    return 'El nombre debe contener al menos 2 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo: Código único
              TextFormField(
                controller: _codigoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código Único *',
                  hintText: 'Ej. LP-001',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                  border: OutlineInputBorder(),
                  helperText: 'Debe ser único en todo el catálogo de productos.',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El código es obligatorio.';
                  }
                  if (val.trim().length < 2) {
                    return 'El código debe tener al menos 2 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Selector y campo de Categoría
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryDropdown,
                decoration: const InputDecoration(
                  labelText: 'Categoría Sugerida',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _categoriasSugeridas.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryDropdown = val;
                    if (val != null && val != 'Otra...') {
                      _categoriaCtrl.text = val;
                    } else if (val == 'Otra...') {
                      _categoriaCtrl.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _categoriaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Categoría *',
                  hintText: 'Ej. Tecnología, Accesorios, Audio...',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'La categoría es obligatoria.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fila con Precio y Cantidad
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precioCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio Unitario *',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d{0,2}')),
                      ],
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Requerido';
                        }
                        final num = double.tryParse(val.trim().replaceAll(',', '.'));
                        if (num == null || num <= 0) {
                          return 'Debe ser > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cantidadCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad *',
                        hintText: '0',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Requerido';
                        }
                        final num = int.tryParse(val.trim());
                        if (num == null || num < 0) {
                          return 'Debe ser ≥ 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Campo: Descripción
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción del Producto (Opcional)',
                  hintText: 'Detalles técnicos, garantía, especificaciones...',
                  prefixIcon: Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 28),

              // Botón Guardar
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSaving ? null : _guardar,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  isSaving
                      ? 'Guardando en la API...'
                      : isEditing
                          ? 'Actualizar Producto'
                          : 'Registrar Producto',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSaving ? null : () => context.pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
