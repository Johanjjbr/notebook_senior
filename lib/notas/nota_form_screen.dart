import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/providers/notas_provider.dart';
import '../core/theme/app_theme.dart';
import '../models/nota.dart';
import '../models/enums.dart';
import '../widgets/categoria_filter_chips.dart';
import '../widgets/shimmer_loading.dart';
import '../l10n/app_localizations.dart';

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
  Recurrencia _recurrencia = Recurrencia.none;
  DateTime? _recurrenciaFin;
  Nota? _notaOriginal;
  bool _cargando = true;
  bool _isDirty = false;
  bool _guardando = false;
  Timer? _autoSaveTimer;
  String _ultimoContenidoGuardado = '';
  String _ultimoTituloGuardado = '';

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
      _recurrencia = _notaOriginal!.recurrencia;
      _recurrenciaFin = _notaOriginal!.recurrenciaFin;
      _ultimoContenidoGuardado = _notaOriginal!.contenido;
      _ultimoTituloGuardado = _notaOriginal!.titulo;
    }
    if (provider.categorias.isEmpty) {
      await provider.cargarCategorias();
    }
    _tituloController.addListener(_onContentChanged);
    _contenidoController.addListener(_onContentChanged);
    if (mounted) setState(() => _cargando = false);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final currentTitulo = _tituloController.text;
    final currentContenido = _contenidoController.text;
    final changed = currentTitulo != _ultimoTituloGuardado ||
        currentContenido != _ultimoContenidoGuardado;
    if (!_isDirty && changed) {
      setState(() => _isDirty = true);
    }
    _autoSaveTimer?.cancel();
    if (changed && _notaOriginal != null) {
      _autoSaveTimer = Timer(const Duration(seconds: 3), _autoGuardar);
    }
  }

  Future<void> _autoGuardar() async {
    if (!_isDirty || _notaOriginal == null) return;
    final titulo = _tituloController.text.trim();
    final contenido = _contenidoController.text.trim();
    if (titulo.isEmpty && contenido.isEmpty) return;

    if (mounted) setState(() => _guardando = true);
    final provider = context.read<NotasProvider>();
    await provider.autoGuardarNota(
      _notaOriginal!.copyWith(
        titulo: titulo,
        contenido: contenido,
        color: _colorSeleccionado,
      ),
    );
    _ultimoContenidoGuardado = contenido;
    _ultimoTituloGuardado = titulo;
    if (mounted) {
      setState(() {
        _isDirty = false;
        _guardando = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    _autoSaveTimer?.cancel();
    final provider = context.read<NotasProvider>();

    if (_notaOriginal != null) {
      await provider.actualizarNota(
        _notaOriginal!.copyWith(
          titulo: _tituloController.text.trim(),
          contenido: _contenidoController.text.trim(),
          color: _colorSeleccionado,
          recurrencia: _recurrencia,
          recurrenciaFin: _recurrenciaFin,
        ),
        categoriaIds: _categoriaIds,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noteUpdated)),
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
          recurrencia: _recurrencia,
          recurrenciaFin: _recurrenciaFin,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        categoriaIds: _categoriaIds,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noteCreated)),
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<NotasProvider>();
    final theme = Theme.of(context);

    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.loading)),
        body: const ShimmerForm(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.notaId != null ? l10n.editNote : l10n.newNote),
        actions: [
          if (_guardando)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 6),
                  Text('Guardando...', style: TextStyle(fontSize: 12)),
                ],
              ),
            )
          else if (_isDirty && _notaOriginal != null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Sin guardar', style: TextStyle(fontSize: 12, color: Colors.orange)),
            ),
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
              decoration: InputDecoration(
                labelText: l10n.noteTitle,
                hintText: l10n.noteHint,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? l10n.titleRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contenidoController,
              decoration: InputDecoration(
                labelText: l10n.noteContent,
                hintText: l10n.contentHint,
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              minLines: 5,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 24),
            Text(l10n.color, style: theme.textTheme.titleMedium),
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
            Text('Repetir', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _RecurrenciaSelector(
              value: _recurrencia,
              onChanged: (v) => setState(() => _recurrencia = v),
            ),
            if (_recurrencia != Recurrencia.none) ...[
              const SizedBox(height: 8),
              ListTile(
                dense: true,
                leading: const Icon(Icons.event),
                title: Text(
                  _recurrenciaFin != null
                      ? 'Hasta ${DateFormat('d MMM y').format(_recurrenciaFin!)}'
                      : 'Sin fecha de fin',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_recurrenciaFin != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => _recurrenciaFin = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month, size: 20),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _recurrenciaFin ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (date != null) setState(() => _recurrenciaFin = date);
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(l10n.categories, style: theme.textTheme.titleMedium),
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

class _RecurrenciaSelector extends StatelessWidget {
  final Recurrencia value;
  final ValueChanged<Recurrencia> onChanged;

  const _RecurrenciaSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: Recurrencia.values.map((r) {
          final selected = value == r;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(r.label,
                  style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
              selected: selected,
              selectedColor: Theme.of(context).colorScheme.primary,
              onSelected: (_) => onChanged(r),
            ),
          );
        }).toList(),
      ),
    );
  }
}
