import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/providers/tareas_provider.dart';
import '../core/theme/app_theme.dart';
import '../models/enums.dart';
import '../models/tarea.dart';

const _sortOptions = ['updated_at', 'created_at', 'titulo', 'prioridad'];
const _sortLabels = {
  'updated_at': 'Última modificación',
  'created_at': 'Fecha creación',
  'titulo': 'Título',
  'prioridad': 'Prioridad',
};

class TareasListScreen extends StatefulWidget {
  const TareasListScreen({super.key});

  @override
  State<TareasListScreen> createState() => _TareasListScreenState();
}

class _TareasListScreenState extends State<TareasListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TareasProvider>().cargarTareas();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TareasProvider>().cargarMas();
    }
  }

  Future<void> _eliminarTarea(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<TareasProvider>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmado != true) return;
    await provider.eliminarTarea(id);
    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Tarea eliminada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TareasProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar',
            onSelected: provider.setSortField,
            itemBuilder: (_) => _sortOptions.map((f) => PopupMenuItem(
              value: f,
              child: Text(_sortLabels[f]!),
            )).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _TareasSearchDelegate(provider),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/tareas/nueva'),
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _FiltrosBar(provider: provider),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.cargarTareas(),
                  child: provider.cargando
                      ? const Center(child: CircularProgressIndicator())
                      : provider.tareas.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.checklist, size: 80, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text('Sin tareas',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(color: Colors.grey[600])),
                                  const SizedBox(height: 8),
                                  Text('Toca + para crear una tarea',
                                      style: TextStyle(color: Colors.grey[500])),
                                ],
                              ),
                            ),
                          )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: provider.tareas.length,
                              itemBuilder: (context, index) {
                                final tarea = provider.tareas[index];
                                return _TareaTile(
                                  tarea: tarea,
                                  onToggle: () => provider.toggleCompletada(
                                    tarea.id,
                                    !tarea.completada,
                                  ),
                                  onTap: () => context.go('/tareas/editar/${tarea.id}'),
                                  onEliminar: () => _eliminarTarea(tarea.id),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
          if (provider.cargandoMas)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
    );
  }
}

class _FiltrosBar extends StatelessWidget {
  final TareasProvider provider;

  const _FiltrosBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FiltroChip(
              label: 'Todas',
              selected: provider.filtroEstado == null,
              onSelected: () => provider.setFiltroEstado(null),
            ),
            const SizedBox(width: 8),
            _FiltroChip(
              label: 'Pendientes',
              selected: provider.filtroEstado == 'pendientes',
              onSelected: () => provider.setFiltroEstado('pendientes'),
            ),
            const SizedBox(width: 8),
            _FiltroChip(
              label: 'Completadas',
              selected: provider.filtroEstado == 'completadas',
              onSelected: () => provider.setFiltroEstado('completadas'),
            ),
            const SizedBox(width: 8),
            _FiltroChip(
              label: 'Programadas',
              selected: provider.filtroProgramadas == true,
              onSelected: () => provider.setFiltroProgramadas(!provider.filtroProgramadas),
            ),
            const SizedBox(width: 16),
            _PrioridadChip(
              prioridad: Prioridad.alta,
              selected: provider.filtroPrioridad == Prioridad.alta,
              onSelected: () => provider.setFiltroPrioridad(
                provider.filtroPrioridad == Prioridad.alta ? null : Prioridad.alta,
              ),
            ),
            const SizedBox(width: 4),
            _PrioridadChip(
              prioridad: Prioridad.media,
              selected: provider.filtroPrioridad == Prioridad.media,
              onSelected: () => provider.setFiltroPrioridad(
                provider.filtroPrioridad == Prioridad.media ? null : Prioridad.media,
              ),
            ),
            const SizedBox(width: 4),
            _PrioridadChip(
              prioridad: Prioridad.baja,
              selected: provider.filtroPrioridad == Prioridad.baja,
              onSelected: () => provider.setFiltroPrioridad(
                provider.filtroPrioridad == Prioridad.baja ? null : Prioridad.baja,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _PrioridadChip extends StatelessWidget {
  final Prioridad prioridad;
  final bool selected;
  final VoidCallback onSelected;

  const _PrioridadChip({
    required this.prioridad,
    required this.selected,
    required this.onSelected,
  });

  Color get _color {
    switch (prioridad) {
      case Prioridad.alta:
        return AppTheme.prioridadAlta;
      case Prioridad.media:
        return AppTheme.prioridadMedia;
      case Prioridad.baja:
        return AppTheme.prioridadBaja;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(prioridad.label,
          style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
      selected: selected,
      selectedColor: _color,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _TareaTile extends StatelessWidget {
  final Tarea tarea;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onEliminar;

  const _TareaTile({
    required this.tarea,
    required this.onToggle,
    required this.onTap,
    required this.onEliminar,
  });

  Color get _prioridadColor {
    switch (tarea.prioridad) {
      case Prioridad.alta:
        return AppTheme.prioridadAlta;
      case Prioridad.media:
        return AppTheme.prioridadMedia;
      case Prioridad.baja:
        return AppTheme.prioridadBaja;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: tarea.completada,
                onChanged: (_) => onToggle(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _prioridadColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tarea.titulo,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: tarea.completada
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: tarea.completada ? Colors.grey : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (tarea.fechaVencimiento != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.event, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('d MMM').format(tarea.fechaVencimiento!),
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    if (tarea.checklistItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 2),
                        child: Text(
                          '${tarea.checklistItems.where((i) => i.completada).length}/${tarea.checklistItems.length}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                  const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                ],
                onSelected: (v) {
                  if (v == 'editar') onTap();
                  if (v == 'eliminar') onEliminar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TareasSearchDelegate extends SearchDelegate {
  final TareasProvider provider;

  _TareasSearchDelegate(this.provider);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final tareas = provider.tareas
        .where((t) => t.titulo.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (tareas.isEmpty) {
      return Center(child: Text('Sin resultados para "$query"'));
    }

    return ListView.builder(
      itemCount: tareas.length,
      itemBuilder: (context, index) {
        final tarea = tareas[index];
        return ListTile(
          leading: Checkbox(
            value: tarea.completada,
            onChanged: (_) =>
                provider.toggleCompletada(tarea.id, !tarea.completada),
          ),
          title: Text(tarea.titulo),
          subtitle: tarea.fechaVencimiento != null
              ? Text(DateFormat('d MMM y').format(tarea.fechaVencimiento!))
              : null,
          onTap: () {
            close(context, null);
            context.go('/tareas/editar/${tarea.id}');
          },
        );
      },
    );
  }
}
