import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/providers/tareas_provider.dart';

class TareasSearchDelegate extends SearchDelegate {
  final TareasProvider provider;

  TareasSearchDelegate(this.provider);

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
        .where((t) =>
            t.titulo.toLowerCase().contains(query.toLowerCase()) ||
            t.descripcion.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (tareas.isEmpty) {
      return Center(child: Text('Sin resultados para "$query"'));
    }

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
