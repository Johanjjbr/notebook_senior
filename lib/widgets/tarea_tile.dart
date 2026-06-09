import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/enums.dart';
import '../models/tarea.dart';
import '../core/theme/app_theme.dart';

class TareaTile extends StatelessWidget {
  final Tarea tarea;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onEliminar;

  const TareaTile({
    super.key,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tarea.titulo,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: tarea.completada
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: tarea.completada ? Colors.grey : null,
                                ),
                              ),
                              if (tarea.descripcion.isNotEmpty && !tarea.completada)
                                Text(
                                  tarea.descripcion,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 2),
                      child: Row(
                        children: [
                          if (tarea.fechaVencimiento != null) ...[
                            Icon(Icons.event, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('d MMM').format(tarea.fechaVencimiento!),
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (tarea.checklistItems.isNotEmpty) ...[
                            Icon(Icons.checklist, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${tarea.checklistItems.where((i) => i.completada).length}/${tarea.checklistItems.length}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (tarea.recurrencia != Recurrencia.none) ...[
                            Icon(Icons.repeat, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              tarea.recurrencia.label,
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ],
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
