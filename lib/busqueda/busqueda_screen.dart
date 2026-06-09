import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/notas_provider.dart';
import '../core/providers/tareas_provider.dart';
import '../models/nota.dart';
import '../models/tarea.dart';

class BusquedaScreen extends StatefulWidget {
  const BusquedaScreen({super.key});

  @override
  State<BusquedaScreen> createState() => _BusquedaScreenState();
}

class _BusquedaScreenState extends State<BusquedaScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final notasProvider = context.watch<NotasProvider>();
    final tareasProvider = context.watch<TareasProvider>();
    final query = _query;

    final notasFiltradas = query.isEmpty
        ? <Nota>[]
        : notasProvider.notas
            .where((n) =>
                n.titulo.toLowerCase().contains(query) ||
                n.contenido.toLowerCase().contains(query))
            .toList();

    final tareasFiltradas = query.isEmpty
        ? <Tarea>[]
        : tareasProvider.tareas
            .where((t) =>
                t.titulo.toLowerCase().contains(query) ||
                t.descripcion.toLowerCase().contains(query))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar notas y tareas...',
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _debounce?.cancel();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: query.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Busca en tus notas y tareas',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Escribe arriba para empezar',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (notasFiltradas.isNotEmpty) ...[
                  Text('Notas',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...notasFiltradas.map((n) => ListTile(
                        leading: const Icon(Icons.note_alt),
                        title: Text(
                            n.titulo.isNotEmpty ? n.titulo : 'Sin título'),
                        subtitle: Text(n.contenido,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.pushNamed(
                            context, '/notas/editar/${n.id}'),
                      )),
                  const SizedBox(height: 16),
                ],
                if (tareasFiltradas.isNotEmpty) ...[
                  Text('Tareas',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...tareasFiltradas.map((t) => ListTile(
                        leading: Checkbox(
                          value: t.completada,
                          onChanged: (_) => tareasProvider
                              .toggleCompletada(t.id, !t.completada),
                        ),
                        title: Text(t.titulo),
                        subtitle: t.descripcion.isNotEmpty
                            ? Text(t.descripcion,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)
                            : null,
                        onTap: () => Navigator.pushNamed(
                            context, '/tareas/editar/${t.id}'),
                      )),
                ],
                if (notasFiltradas.isEmpty && tareasFiltradas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text('Sin resultados para "$query"',
                          style: TextStyle(color: Colors.grey[600])),
                    ),
                  ),
              ],
            ),
    );
  }
}
