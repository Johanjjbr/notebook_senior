import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/providers/tareas_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/tarea_tile.dart';
import '../widgets/filtros_bar.dart';
import '../widgets/search_delegate_tareas.dart';
import '../l10n/app_localizations.dart';

const _sortOptions = ['updated_at', 'created_at', 'titulo', 'prioridad'];

String _sortLabel(String field, AppLocalizations l10n) {
  switch (field) {
    case 'updated_at':
      return l10n.sortLastModified;
    case 'created_at':
      return l10n.sortCreated;
    case 'titulo':
      return l10n.sortTitle;
    case 'prioridad':
      return l10n.sortPriority;
    default:
      return field;
  }
}

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

  Future<void> _eliminarTarea(String id, {bool showConfirm = true}) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<TareasProvider>();
    if (showConfirm) {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.deleteTask),
          content: Text(l10n.deleteTaskConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
          ],
        ),
      );
      if (confirmado != true || !context.mounted) return;
    }
    await provider.eliminarTarea(id);
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.taskDeleted),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => context.read<TareasProvider>().restaurarUltimaTarea(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<TareasProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tasksTitle),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.sortBy,
            onSelected: provider.setSortField,
            itemBuilder: (_) => _sortOptions.map((f) => PopupMenuItem(
              value: f,
              child: Text(_sortLabel(f, l10n)),
            )).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: TareasSearchDelegate(provider));
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
              FiltrosBar(
                filtroEstado: provider.filtroEstado,
                filtroProgramadas: provider.filtroProgramadas,
                filtroPrioridad: provider.filtroPrioridad,
                onChangedEstado: provider.setFiltroEstado,
                onChangedProgramadas: provider.setFiltroProgramadas,
                onChangedPrioridad: provider.setFiltroPrioridad,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.cargarTareas(),
                  child: provider.cargando
                      ? const ShimmerList()
                      : provider.tareas.isEmpty
                          ? EmptyState(
                              icon: Icons.checklist,
                              title: l10n.noTasks,
                              subtitle: l10n.createTaskHint,
                              actionLabel: l10n.createTask,
                              actionIcon: Icons.add,
                              onAction: () => context.go('/tareas/nueva'),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: provider.tareas.length,
                              itemBuilder: (context, index) {
                                final tarea = provider.tareas[index];
                                return Dismissible(
                                  key: ValueKey(tarea.id),
                                  direction: DismissDirection.horizontal,
                                  background: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.check_circle, color: Colors.white),
                                  ),
                                  secondaryBackground: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  confirmDismiss: (direction) async {
                                    if (direction == DismissDirection.endToStart) {
                                      final l10n = AppLocalizations.of(context)!;
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text(l10n.deleteTask),
                                          content: Text(l10n.deleteConfirm),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _eliminarTarea(tarea.id, showConfirm: false);
                                        return true;
                                      }
                                      return false;
                                    }
                                    provider.toggleCompletada(tarea.id, !tarea.completada);
                                    return true;
                                  },
                                  child: TareaTile(
                                    tarea: tarea,
                                    onToggle: () => provider.toggleCompletada(
                                      tarea.id,
                                      !tarea.completada,
                                    ),
                                    onTap: () => context.go('/tareas/editar/${tarea.id}'),
                                    onEliminar: () => _eliminarTarea(tarea.id),
                                  ),
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
