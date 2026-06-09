import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/providers/notas_provider.dart';
import '../models/nota.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/nota_card.dart';
import '../widgets/search_delegate_notas.dart';
import '../l10n/app_localizations.dart';

const _sortOptions = ['updated_at', 'created_at', 'titulo'];

String _sortLabel(String field, AppLocalizations l10n) {
  switch (field) {
    case 'updated_at':
      return l10n.sortLastModified;
    case 'created_at':
      return l10n.sortCreated;
    case 'titulo':
      return l10n.sortTitle;
    default:
      return field;
  }
}

class NotasListScreen extends StatefulWidget {
  const NotasListScreen({super.key});

  @override
  State<NotasListScreen> createState() => _NotasListScreenState();
}

class _NotasListScreenState extends State<NotasListScreen> {
  final _scrollController = ScrollController();
  bool _mostrarArchivadas = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotasProvider>().cargarNotas();
      context.read<NotasProvider>().cargarCategorias();
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
      context.read<NotasProvider>().cargarMas();
    }
  }

  Future<void> _eliminarNota(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<NotasProvider>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteNote),
        content: Text(l10n.deleteNoteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmado != true) return;
    await provider.eliminarNota(id);
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.noteDeleted),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => context.read<NotasProvider>().restaurarUltimaNota(),
          ),
        ),
      );
    }
  }

  Future<void> _toggleArchivar(Nota nota) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<NotasProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (nota.archivada) {
      await provider.desarchivarNota(nota.id);
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(l10n.noteRestored)));
    } else {
      await provider.archivarNota(nota.id);
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(l10n.noteArchived)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<NotasProvider>();
    final notas = provider.notas.where((n) => n.archivada == _mostrarArchivadas).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_mostrarArchivadas ? l10n.archivedNotes : l10n.notesTitle),
        actions: [
          IconButton(
            icon: Icon(_mostrarArchivadas ? Icons.unarchive : Icons.archive),
            tooltip: _mostrarArchivadas ? 'Ver activas' : 'Ver archivadas',
            onPressed: () => setState(() => _mostrarArchivadas = !_mostrarArchivadas),
          ),
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
              showSearch(context: context, delegate: NotasSearchDelegate(provider));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => provider.cargarNotas(),
            child: provider.cargando
                ? const ShimmerGrid()
                : notas.isEmpty
                    ? EmptyState(
                        icon: Icons.note_alt_outlined,
                        title: _mostrarArchivadas ? l10n.noArchivedNotes : l10n.noNotes,
                        subtitle: _mostrarArchivadas ? l10n.archiveHint : l10n.createNoteHint,
                        actionLabel: _mostrarArchivadas ? null : l10n.createNote,
                        actionIcon: Icons.add,
                        onAction: _mostrarArchivadas ? null : () => context.go('/notas/nueva'),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 900 ? 4
                              : constraints.maxWidth > 600 ? 3 : 2;
                          return NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollEndNotification &&
                                  _scrollController.position.pixels >=
                                      _scrollController.position.maxScrollExtent - 200) {
                                context.read<NotasProvider>().cargarMas();
                              }
                              return false;
                            },
                            child: GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(12),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: constraints.maxWidth > 600 ? 1.2 : 0.9,
                              ),
                              itemCount: notas.length,
                              itemBuilder: (context, index) {
                                final nota = notas[index];
                                return Dismissible(
                                  key: ValueKey(nota.id),
                                  direction: DismissDirection.horizontal,
                                  background: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.archive, color: Colors.white),
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
                                          title: Text(l10n.deleteNote),
                                          content: Text(l10n.deleteConfirm),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _eliminarNota(nota.id);
                                        return true;
                                      }
                                      return false;
                                    }
                                    await _toggleArchivar(nota);
                                    return true;
                                  },
                                  child: NotaCard(
                                    nota: nota,
                                    onArchivar: () => _toggleArchivar(nota),
                                    onEliminar: () => _eliminarNota(nota.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/notas/nueva'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
