import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/calendario_provider.dart';
import 'widgets/calendar_grid.dart';
import 'widgets/day_detail_sheet.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarioProvider>().cargarMes();
    });
  }

  void _onDayTap(DateTime dia) {
    DayDetailSheet.mostrar(context, dia);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarioProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.mesTitulo),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => provider.irMesAnterior(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => provider.irMesSiguiente(),
          ),
          TextButton(
            onPressed: () => provider.irAHoy(),
            child: const Text('Hoy'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.cargarMes(),
        child: provider.cargandoLista
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  CalendarGrid(
                    provider: provider,
                    onDayTap: _onDayTap,
                  ),
                  const SizedBox(height: 16),
                  _Leyenda(theme: theme),
                  const SizedBox(height: 16),
                  _ResumenMes(provider: provider, theme: theme),
                ],
              ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final ThemeData theme;

  const _Leyenda({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ItemLeyenda(color: theme.colorScheme.primary, label: 'Notas'),
        const SizedBox(width: 16),
        _ItemLeyenda(color: Colors.blue, label: 'Tareas'),
        const SizedBox(width: 16),
        _ItemLeyenda(color: Colors.orange, label: 'Recordatorios'),
      ],
    );
  }
}

class _ItemLeyenda extends StatelessWidget {
  final Color color;
  final String label;

  const _ItemLeyenda({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _ResumenMes extends StatelessWidget {
  final CalendarioProvider provider;
  final ThemeData theme;

  const _ResumenMes({required this.provider, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del mes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Estadistica(
                  icon: Icons.note_alt,
                  color: theme.colorScheme.primary,
                  cantidad: provider.cantidadNotasMes,
                  label: 'Notas',
                ),
                _Estadistica(
                  icon: Icons.checklist,
                  color: Colors.blue,
                  cantidad: provider.cantidadTareasMes,
                  label: 'Tareas pendientes',
                ),
                _Estadistica(
                  icon: Icons.alarm,
                  color: Colors.orange,
                  cantidad: provider.cantidadRecordatoriosMes,
                  label: 'Recordatorios',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Estadistica extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int cantidad;
  final String label;

  const _Estadistica({
    required this.icon,
    required this.color,
    required this.cantidad,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            cantidad.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
