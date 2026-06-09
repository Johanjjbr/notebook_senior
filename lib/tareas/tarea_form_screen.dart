import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/providers/tareas_provider.dart';
import '../models/tarea.dart';
import '../models/enums.dart';
import '../models/checklist_item.dart';
import '../widgets/categoria_filter_chips.dart';
import '../widgets/shimmer_loading.dart';
import '../l10n/app_localizations.dart';

class TareaFormScreen extends StatefulWidget {
  final String? tareaId;

  const TareaFormScreen({super.key, this.tareaId});

  @override
  State<TareaFormScreen> createState() => _TareaFormScreenState();
}

class _TareaFormScreenState extends State<TareaFormScreen> {
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _checklistControllers = <TextEditingController>[];
  final _checklistNodes = <FocusNode>[];
  final _uuid = const Uuid();

  Prioridad _prioridad = Prioridad.media;
  DateTime? _fechaVencimiento;
  Recurrencia _recurrencia = Recurrencia.none;
  DateTime? _recurrenciaFin;
  List<String> _categoriaIds = [];
  Tarea? _tareaOriginal;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initForm());
  }

  Future<void> _initForm() async {
    final provider = context.read<TareasProvider>();
    if (widget.tareaId != null) {
      if (provider.tareas.isEmpty) {
        await provider.cargarTareas();
      }
      _tareaOriginal = provider.tareas.firstWhere(
        (t) => t.id == widget.tareaId,
        orElse: () => throw Exception('Tarea no encontrada'),
      );
      _tituloController.text = _tareaOriginal!.titulo;
      _descripcionController.text = _tareaOriginal!.descripcion;
      _prioridad = _tareaOriginal!.prioridad;
      _fechaVencimiento = _tareaOriginal!.fechaVencimiento;
      _recurrencia = _tareaOriginal!.recurrencia;
      _recurrenciaFin = _tareaOriginal!.recurrenciaFin;
      _categoriaIds = _tareaOriginal!.categorias.map((c) => c.id).toList();
      for (final item in _tareaOriginal!.checklistItems) {
        final ctrl = TextEditingController(text: item.texto);
        _checklistControllers.add(ctrl);
        _checklistNodes.add(FocusNode());
      }
    } else {
      _agregarItemChecklist();
    }
    if (provider.categorias.isEmpty) {
      await provider.cargarCategorias();
    }
    if (mounted) setState(() => _cargando = false);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    for (final c in _checklistControllers) {
      c.dispose();
    }
    for (final n in _checklistNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _agregarItemChecklist() {
    setState(() {
      _checklistControllers.add(TextEditingController());
      _checklistNodes.add(FocusNode());
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _checklistNodes.last.requestFocus();
    });
  }

  void _removerItemChecklist(int index) {
    setState(() {
      _checklistControllers[index].dispose();
      _checklistNodes[index].dispose();
      _checklistControllers.removeAt(index);
      _checklistNodes.removeAt(index);
    });
  }

  void _onReorderChecklist(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final ctrl = _checklistControllers.removeAt(oldIndex);
      final node = _checklistNodes.removeAt(oldIndex);
      _checklistControllers.insert(newIndex, ctrl);
      _checklistNodes.insert(newIndex, node);
    });
  }

  Future<void> _seleccionarFecha() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaVencimiento ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) setState(() => _fechaVencimiento = date);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TareasProvider>();
    final items = _checklistControllers
        .where((c) => c.text.trim().isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map((e) {
          final original = _tareaOriginal?.checklistItems
              .where((i) => i.texto == e.value.text.trim())
              .firstOrNull;
          return ChecklistItem(
            id: original?.id ?? _uuid.v4(),
            tareaId: _tareaOriginal?.id ?? '',
            texto: e.value.text.trim(),
            completada: original?.completada ?? false,
            orden: e.key,
          );
        })
        .toList();

    if (_tareaOriginal != null) {
      await provider.actualizarTarea(
        _tareaOriginal!.copyWith(
          titulo: _tituloController.text.trim(),
          descripcion: _descripcionController.text.trim(),
          prioridad: _prioridad,
          fechaVencimiento: _fechaVencimiento,
          recurrencia: _recurrencia,
          recurrenciaFin: _recurrenciaFin,
        ),
        checklistItems: items,
        categoriaIds: _categoriaIds,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.taskUpdated)),
        );
      }
    } else {
      await provider.crearTarea(
        Tarea(
          id: '',
          userId: '',
          titulo: _tituloController.text.trim(),
          descripcion: _descripcionController.text.trim(),
          prioridad: _prioridad,
          fechaVencimiento: _fechaVencimiento,
          recurrencia: _recurrencia,
          recurrenciaFin: _recurrenciaFin,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        checklistItems: items,
        categoriaIds: _categoriaIds,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.taskCreated)),
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<TareasProvider>();
    final theme = Theme.of(context);

    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.loading)),
        body: const ShimmerForm(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tareaId != null ? l10n.editTask : l10n.newTaskTitle),
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
              decoration: InputDecoration(
                labelText: l10n.taskTitle,
                hintText: l10n.taskHint,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? l10n.titleRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              decoration: InputDecoration(
                labelText: l10n.taskDescription,
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Text(l10n.priority, style: theme.textTheme.titleMedium),
                const Spacer(),
                SegmentedButton<Prioridad>(
                  segments: [
                    ButtonSegment(value: Prioridad.baja, label: Text(l10n.low), icon: Icon(Icons.arrow_downward, size: 16)),
                    ButtonSegment(value: Prioridad.media, label: Text(l10n.medium), icon: Icon(Icons.remove, size: 16)),
                    ButtonSegment(value: Prioridad.alta, label: Text(l10n.high), icon: Icon(Icons.arrow_upward, size: 16)),
                  ],
                  selected: {_prioridad},
                  onSelectionChanged: (v) => setState(() => _prioridad = v.first),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ListTile(
              leading: const Icon(Icons.event),
              title: Text(_fechaVencimiento != null
                  ? DateFormat('d MMM y').format(_fechaVencimiento!)
                  : l10n.noDueDate),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_fechaVencimiento != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _fechaVencimiento = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: _seleccionarFecha,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
                          initialDate: _recurrenciaFin ?? (_fechaVencimiento ?? DateTime.now()).add(const Duration(days: 30)),
                          firstDate: _fechaVencimiento ?? DateTime.now(),
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

            Text(l10n.checklist, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _checklistControllers.length,
              onReorder: _onReorderChecklist,
              itemBuilder: (context, i) {
                return Padding(
                  key: ValueKey('checklist_$i'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: i,
                        child: Icon(Icons.drag_handle, color: Colors.grey[400]),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _checklistControllers[i],
                          focusNode: _checklistNodes[i],
                          decoration: InputDecoration(
                            hintText: '${l10n.stepHint} ${i + 1}',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _removerItemChecklist(i),
                      ),
                    ],
                  ),
                );
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.addStep),
              onPressed: _agregarItemChecklist,
            ),
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
