import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/notas_provider.dart';

class NotasSearchDelegate extends SearchDelegate {
  final NotasProvider provider;

  NotasSearchDelegate(this.provider);

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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
