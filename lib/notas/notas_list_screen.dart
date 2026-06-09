import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/providers/notas_provider.dart';
import '../models/nota.dart';
import '../widgets/color_utils.dart';

const _sortOptions = ['updated_at', 'created_at', 'titulo'];
const _sortLabels = {'updated_at': 'Última modificación', 'created_at': 'Fecha creación', 'titulo': 'Título'};

class NotasListScreen extends StatefulWidget {
  const NotasListScreen({super.key});

  @override
  State<NotasListScreen> createState() => _NotasListScreenState();
}

class _NotasListScreenState extends State<NotasListScreen> {
  final _searchController = TextEditingController();
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
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotasProvider>().cargarMas();
    }
  }

  Future<void> _eliminarNota(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<NotasProvider>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmado != true) return;
    await provider.eliminarNota(id);
    messenger.showSnackBar(
      const SnackBar(content: Text('Nota eliminada')),
    );
  }

  Future<void> _toggleArchivar(Nota nota) async {
    final provider = context.read<NotasProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (nota.archivada) {
      await provider.desarchivarNota(nota.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Nota restaurada')),
      );
    } else {
      await provider.archivarNota(nota.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Nota archivada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotasProvider>();
    final theme = Theme.of(context);

    final notas = provider.notas.where((n) => n.archivada == _mostrarArchivadas).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_mostrarArchivadas ? 'Notas archivadas' : 'Notas'),
        actions: [
          IconButton(
            icon: Icon(_mostrarArchivadas ? Icons.unarchive : Icons.archive),
            tooltip: _mostrarArchivadas ? 'Ver activas' : 'Ver archivadas',
            onPressed: () => setState(() => _mostrarArchivadas = !_mostrarArchivadas),
          ),
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
                delegate: _NotasSearchDelegate(provider),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => provider.cargarNotas(),
            child: provider.cargando
                ? const Center(child: CircularProgressIndicator())
                : provider.notas.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _mostrarArchivadas ? 'Sin notas archivadas' : 'Sin notas',
                              style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _mostrarArchivadas ? 'Archiva notas para verlas aquí' : 'Toca + para crear una nota',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 900
                              ? 4
                              : constraints.maxWidth > 600
                                  ? 3
                                  : 2;
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
                                final bgColor = parseColor(nota.color);
                                final textColor = bgColor.computeLuminance() > 0.5
                                    ? Colors.black87
                                    : Colors.white;
                                final mutedColor = textColor.withAlpha(180);
                                return Card(
                                  color: bgColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                nota.titulo.isNotEmpty
                                                    ? nota.titulo
                                                    : 'Sin titulo',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: textColor,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              padding: EdgeInsets.zero,
                                              iconSize: 18,
                                              icon: Icon(Icons.more_vert, color: mutedColor),
                                              onSelected: (v) {
                                                switch (v) {
                                                  case 'editar':
                                                    context.go('/notas/editar/${nota.id}');
                                                  case 'archivar':
                                                    _toggleArchivar(nota);
                                                  case 'eliminar':
                                                    _eliminarNota(nota.id);
                                                }
                                              },
                                              itemBuilder: (_) => [
                                                const PopupMenuItem(
                                                    value: 'editar',
                                                    child: Text('Editar')),
                                                PopupMenuItem(
                                                  value: 'archivar',
                                                  child: Text(nota.archivada
                                                      ? 'Desarchivar'
                                                      : 'Archivar'),
                                                ),
                                                const PopupMenuItem(
                                                    value: 'eliminar',
                                                    child: Text('Eliminar')),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () =>
                                                context.go('/notas/editar/${nota.id}'),
                                            child: Text(
                                              nota.contenido,
                                              style:
                                                  TextStyle(fontSize: 12, color: textColor),
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        if (nota.categorias.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Wrap(
                                              spacing: 4,
                                              children: nota.categorias.map((c) =>
                                                  Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: parseColor(c.color)
                                                      .withAlpha(80),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(c.nombre,
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: textColor)),
                                              )).toList(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
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

class _NotasSearchDelegate extends SearchDelegate {
  final NotasProvider provider;

  _NotasSearchDelegate(this.provider);

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
    final notas = provider.notas.where((n) =>
        n.titulo.toLowerCase().contains(query.toLowerCase()) ||
        n.contenido.toLowerCase().contains(query.toLowerCase())).toList();

    if (notas.isEmpty) {
      return Center(child: Text('Sin resultados para "$query"'));
    }

    return ListView.builder(
      itemCount: notas.length,
      itemBuilder: (context, index) {
        final nota = notas[index];
        return ListTile(
          title: Text(nota.titulo.isNotEmpty ? nota.titulo : 'Sin título'),
          subtitle: Text(nota.contenido, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () {
            close(context, null);
            context.go('/notas/editar/${nota.id}');
          },
        );
      },
    );
  }
}
