import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/calendario_provider.dart';
import '../../models/nota.dart';
import '../../models/tarea.dart';
import '../../models/recordatorio.dart';
import '../../models/enums.dart';

class DayDetailSheet extends StatelessWidget {
  final DateTime fecha;

  const DayDetailSheet({super.key, required this.fecha});

  static Future<void> mostrar(BuildContext context, DateTime fecha) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CalendarioProvider>(),
        child: DayDetailSheet(fecha: fecha),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarioProvider>();
    final eventos = provider.obtenerEventosDelDia(fecha);
    final theme = Theme.of(context);

    final notas = eventos.whereType<Nota>().toList();
    final tareas = eventos.whereType<Tarea>().toList();
    final recordatorios = eventos.whereType<Recordatorio>().toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                DateFormat("EEEE, d 'de' MMMM 'de' y", 'es')
                    .format(fecha),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${eventos.length} evento${eventos.length != 1 ? 's' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: eventos.isEmpty
                    ? _EmptyState(fecha: fecha, theme: theme)
                    : ListView(
                        controller: scrollController,
                        children: [
                          if (recordatorios.isNotEmpty) ...[
                            _SeccionHeader(
                              icon: Icons.alarm,
                              label: 'Recordatorios',
                              color: Colors.orange,
                            ),
                            ...recordatorios.map((r) => _RecordatorioItem(
                                  recordatorio: r,
                                  onCompletar: () => provider
                                      .completarRecordatorio(r.id),
                                  onEliminar: () => provider
                                      .eliminarRecordatorio(r.id),
                                )),
                          ],
                          if (tareas.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _SeccionHeader(
                              icon: Icons.checklist,
                              label: 'Tareas',
                              color: Colors.blue,
                            ),
                            ...tareas.map((t) => _TareaItem(
                                  tarea: t,
                                  onToggle: (completada) => provider
                                      .toggleTareaCompletada(t.id, completada),
                                  onEliminar: () =>
                                      provider.eliminarTarea(t.id),
                                )),
                          ],
                          if (notas.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _SeccionHeader(
                              icon: Icons.note_alt,
                              label: 'Notas',
                              color: Colors.indigo,
                            ),
                            ...notas.map((n) => _NotaItem(
                                  nota: n,
                                  onEliminar: () =>
                                      provider.eliminarNota(n.id),
                                )),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.checklist, size: 18),
                      label: const Text('Tarea'),
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/tareas/nueva');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.alarm, size: 18),
                      label: const Text('Recordatorio'),
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/recordatorios');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final DateTime fecha;
  final ThemeData theme;

  const _EmptyState({required this.fecha, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Sin eventos',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay notas, tareas ni recordatorios\npara este día',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _SeccionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SeccionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordatorioItem extends StatelessWidget {
  final Recordatorio recordatorio;
  final VoidCallback onCompletar;
  final VoidCallback onEliminar;

  const _RecordatorioItem({
    required this.recordatorio,
    required this.onCompletar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: recordatorio.completado
              ? Colors.green.withAlpha(30)
              : Colors.orange.withAlpha(30),
          child: Icon(
            recordatorio.completado ? Icons.check : Icons.alarm,
            size: 16,
            color: recordatorio.completado ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          recordatorio.titulo,
          style: TextStyle(
            fontSize: 14,
            decoration: recordatorio.completado
                ? TextDecoration.lineThrough
                : null,
            color: recordatorio.completado ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          DateFormat('HH:mm').format(recordatorio.fechaHora),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (!recordatorio.completado)
              const PopupMenuItem(
                value: 'completar',
                child: Text('Completar'),
              ),
            const PopupMenuItem(
              value: 'eliminar',
              child: Text('Eliminar'),
            ),
          ],
          onSelected: (v) {
            if (v == 'completar') onCompletar();
            if (v == 'eliminar') onEliminar();
          },
        ),
      ),
    );
  }
}

class _TareaItem extends StatelessWidget {
  final Tarea tarea;
  final void Function(bool) onToggle;
  final VoidCallback onEliminar;

  const _TareaItem({
    required this.tarea,
    required this.onToggle,
    required this.onEliminar,
  });

  Color _prioridadColor(Prioridad p) {
    switch (p) {
      case Prioridad.alta:
        return Colors.red;
      case Prioridad.media:
        return Colors.orange;
      case Prioridad.baja:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: Checkbox(
          value: tarea.completada,
          onChanged: (v) => onToggle(v ?? false),
        ),
        title: Text(
          tarea.titulo,
          style: TextStyle(
            fontSize: 14,
            decoration:
                tarea.completada ? TextDecoration.lineThrough : null,
            color: tarea.completada ? Colors.grey : null,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _prioridadColor(tarea.prioridad),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              tarea.prioridad.name,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'eliminar',
              child: Text('Eliminar'),
            ),
          ],
          onSelected: (v) {
            if (v == 'eliminar') onEliminar();
          },
        ),
      ),
    );
  }
}

class _NotaItem extends StatelessWidget {
  final Nota nota;
  final VoidCallback onEliminar;

  const _NotaItem({
    required this.nota,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.indigo.withAlpha(30),
          child: const Icon(Icons.note_alt, size: 16, color: Colors.indigo),
        ),
        title: Text(
          nota.titulo.isNotEmpty ? nota.titulo : 'Sin título',
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          nota.contenido.isNotEmpty
              ? nota.contenido.length > 40
                  ? '${nota.contenido.substring(0, 40)}...'
                  : nota.contenido
              : 'Sin contenido',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'eliminar',
              child: Text('Eliminar'),
            ),
          ],
          onSelected: (v) {
            if (v == 'eliminar') onEliminar();
          },
        ),
      ),
    );
  }
}
