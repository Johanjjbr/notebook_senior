import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/providers/notas_provider.dart';
import '../core/providers/tareas_provider.dart';
import '../core/providers/recordatorios_provider.dart';
import '../widgets/dashboard_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notasProvider = context.watch<NotasProvider>();
    final tareasProvider = context.watch<TareasProvider>();
    final recordatoriosProvider = context.watch<RecordatoriosProvider>();
    final theme = Theme.of(context);

    final notasRecientes = notasProvider.notas.take(3).toList();
    final tareasHoy = tareasProvider.tareas
        .where((t) =>
            !t.completada &&
            t.fechaVencimiento != null &&
            DateFormat('yMd').format(t.fechaVencimiento!) ==
                DateFormat('yMd').format(DateTime.now()))
        .toList();
    final proximoRecordatorio = recordatoriosProvider.proximos.isNotEmpty
        ? recordatoriosProvider.proximos.first
        : null;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          notasProvider.cargarNotas(),
          tareasProvider.cargarTareas(),
          recordatoriosProvider.cargarRecordatorios(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Resumen del día', style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 16),

          if (proximoRecordatorio != null)
            DashboardCard(
              icon: Icons.notifications_active,
              color: Colors.orange,
              title: 'Próximo recordatorio',
              subtitle:
                  '${proximoRecordatorio.titulo} - ${DateFormat('HH:mm').format(proximoRecordatorio.fechaHora)}',
              onTap: () => context.go('/recordatorios'),
            ),

          if (tareasHoy.isNotEmpty)
            DashboardCard(
              icon: Icons.today,
              color: Colors.blue,
              title: 'Tareas para hoy',
              subtitle: '${tareasHoy.length} tarea${tareasHoy.length > 1 ? 's' : ''} pendiente${tareasHoy.length > 1 ? 's' : ''}',
              onTap: () => context.go('/tareas'),
            ),

          DashboardCard(
            icon: Icons.note_alt,
            color: Colors.indigo,
            title: 'Notas recientes',
            subtitle: '${notasProvider.notas.length} nota${notasProvider.notas.length != 1 ? 's' : ''} • ${notasRecientes.isNotEmpty ? notasRecientes.first.titulo : 'Ninguna'}',
            onTap: () => context.go('/notas'),
          ),

          if (tareasProvider.tareas.any((t) => !t.completada && t.fechaVencimiento != null))
            DashboardCard(
              icon: Icons.date_range,
              color: Colors.teal,
              title: 'Tareas programadas',
              subtitle: '${tareasProvider.tareas.where((t) => !t.completada && t.fechaVencimiento != null).length} tarea(s) con fecha asignada',
              onTap: () => context.go('/tareas'),
            ),

          const SizedBox(height: 24),
          Text('Acceso rápido', style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AccionRapida(
                icon: Icons.lightbulb_outline,
                label: 'Nota rápida',
                color: Colors.amber,
                onTap: () => context.go('/notas/nueva'),
              ),
              AccionRapida(
                icon: Icons.checklist,
                label: 'Nueva tarea',
                color: Colors.green,
                onTap: () => context.go('/tareas/nueva'),
              ),
              AccionRapida(
                icon: Icons.alarm,
                label: 'Recordatorio',
                color: Colors.orange,
                onTap: () => context.go('/recordatorios'),
              ),
              AccionRapida(
                icon: Icons.search,
                label: 'Buscar',
                color: Colors.purple,
                onTap: () => context.go('/busqueda'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
