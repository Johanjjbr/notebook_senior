import 'package:flutter/material.dart';
import '../models/categoria.dart';

class CategoriaFilterChips extends StatelessWidget {
  final List<Categoria> categorias;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  const CategoriaFilterChips({
    super.key,
    required this.categorias,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (categorias.isEmpty) {
      return Text(
        'Sin categorías.',
        style: TextStyle(color: Colors.grey[500]),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: categorias.map((c) {
        final selected = selectedIds.contains(c.id);
        return FilterChip(
          label: Text(c.nombre),
          selected: selected,
          onSelected: (val) {
            final ids = List<String>.from(selectedIds);
            if (val) {
              ids.add(c.id);
            } else {
              ids.remove(c.id);
            }
            onChanged(ids);
          },
        );
      }).toList(),
    );
  }
}
