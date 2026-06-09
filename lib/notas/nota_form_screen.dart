import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/notas_provider.dart';
import '../core/theme/app_theme.dart';
import '../models/nota.dart';
import '../widgets/categoria_filter_chips.dart';

class NotaFormScreen extends StatefulWidget {
  final String? notaId;

  const NotaFormScreen({super.key, this.notaId});

  @override
  State<NotaFormScreen> createState() => _NotaFormScreenState();
}

class _NotaFormScreenState extends State<NotaFormScreen> {
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _colorSeleccionado = '#FFF3CD';
  List<String> _categoriaIds = [];
  Nota? _notaOriginal;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initForm());
  }

  Future<void> _initForm() async {
    final provider = context.read<NotasProvider>();
    if (widget.notaId != null) {
      if (provider.notas.isEmpty) {
        await provider.cargarNotas();
      }
      _notaOriginal = provider.notas.firstWhere(
        (n) => n.id == widget.notaId,
        orElse: () => throw Exception('Nota no encontrada'),
      );
      _tituloController.text = _notaOriginal!.titulo;
      _contenidoController.text = _notaOriginal!.contenido;
      _colorSeleccionado = _notaOriginal!.color;
      _categoriaIds = _notaOriginal!.categorias.map((c) => c.id).toList();
    }
    if (provider.categorias.isEmpty) {
      await provider.cargarCategorias();
    }
    if (mounted) setState(() => _cargando = false);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<NotasProvider>();

    if (_notaOriginal != null) {
      await provider.actualizarNota(
        _notaOriginal!.copyWith(
          titulo: _tituloController.text.trim(),
          contenido: _contenidoController.text.trim(),
          color: _colorSeleccionado,
        ),
        categoriaIds: _categoriaIds,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota actualizada')),
        );
      }
    } else {
      await provider.crearNota(
        Nota(
          id: '',
          userId: '',
          titulo: _tituloController.text.trim(),
          contenido: _contenidoController.text.trim(),
          color: _colorSeleccionado,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        categoriaIds: _categoriaIds,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota creada')),
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotasProvider>();

    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.notaId != null ? 'Editar nota' : 'Nueva nota'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _guardar,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: '¿De qué trata esta nota?',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'El título es obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contenidoController,
              decoration: const InputDecoration(
                labelText: 'Contenido',
                hintText: 'Escribe aquí...',
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              minLines: 5,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 24),
            Text('Color', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppTheme.notaColores.map((color) {
                final hex = '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                final seleccionado = _colorSeleccionado == hex;
                return GestureDetector(
                  onTap: () => setState(() => _colorSeleccionado = hex),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: seleccionado
                          ? Border.all(color: Colors.black87, width: 2.5)
                          : null,
                    ),
                    child: seleccionado ? const Icon(Icons.check, size: 18) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Categorías', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            CategoriaFilterChips(
              categorias: provider.categorias,
              selectedIds: _categoriaIds,
              onChanged: (ids) => setState(() => _categoriaIds = ids),
            ),
          ],
        ),
      ),
    );
  }
}
