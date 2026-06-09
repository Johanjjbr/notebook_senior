import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../models/nota.dart';
import 'color_utils.dart';

class NotaCard extends StatelessWidget {
  final Nota nota;
  final VoidCallback onArchivar;
  final VoidCallback onEliminar;

  const NotaCard({
    super.key,
    required this.nota,
    required this.onArchivar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nota.titulo.isNotEmpty ? nota.titulo : 'Sin título',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (nota.recurrencia != Recurrencia.none)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.repeat, size: 12, color: mutedColor),
                              const SizedBox(width: 4),
                              Text(
                                nota.recurrencia.label,
                                style: TextStyle(fontSize: 10, color: mutedColor),
                              ),
                            ],
                          ),
                        ),
                    ],
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
                        onArchivar();
                      case 'eliminar':
                        onEliminar();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(
                      value: 'archivar',
                      child: Text(nota.archivada ? 'Desarchivar' : 'Archivar'),
                    ),
                    const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => context.go('/notas/editar/${nota.id}'),
                child: Text(
                  nota.contenido,
                  style: TextStyle(fontSize: 12, color: textColor),
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
                  children: nota.categorias.take(3).map((c) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: parseColor(c.color).withAlpha(80),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(c.nombre,
                          style: TextStyle(fontSize: 10, color: textColor)),
                    ),
                  ).toList()
                    ..addAll(
                      nota.categorias.length > 3
                          ? [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: mutedColor.withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('+${nota.categorias.length - 3}',
                                  style: TextStyle(fontSize: 10, color: mutedColor)),
                            ),
                          ]
                          : [],
                    ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
