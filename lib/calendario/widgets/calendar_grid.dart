import 'package:flutter/material.dart';
import '../../core/providers/calendario_provider.dart';
import 'day_cell.dart';

class CalendarGrid extends StatelessWidget {
  final CalendarioProvider provider;
  final void Function(DateTime dia) onDayTap;

  const CalendarGrid({
    super.key,
    required this.provider,
    required this.onDayTap,
  });

  static const _diasSemana = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final primerDia = provider.primerDiaMes;
    final diaSemanaInicio = provider.diaSemanaInicio;
    final diasEnMes = provider.diasEnMes;

    final totalCeldas = diaSemanaInicio + diasEnMes;
    final filas = (totalCeldas / 7).ceil();

    return Column(
      children: [
        Row(
          children: _diasSemana.map((d) => Expanded(
            child: Center(
              child: Text(
                d,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 4),
        ...List.generate(filas, (fila) {
          return Row(
            children: List.generate(7, (col) {
              final indice = fila * 7 + col;
              final diaNum = indice - diaSemanaInicio + 1;

              if (diaNum < 1 || diaNum > diasEnMes) {
                return const Expanded(child: SizedBox.shrink());
              }

              final fecha = DateTime(primerDia.year, primerDia.month, diaNum);
              final esHoy = provider.esMismoDia(fecha, ahora);

              return Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DayCell(
                    dia: diaNum,
                    esHoy: esHoy,
                    tieneNotas: provider.notas
                        .any((n) => provider.esMismoDia(n.createdAt, fecha)),
                    tieneTareas: provider.tareas.any((t) =>
                        t.fechaVencimiento != null &&
                        provider.esMismoDia(t.fechaVencimiento!, fecha)),
                    tieneRecordatorios: provider.recordatorios
                        .any((r) => provider.esMismoDia(r.fechaHora, fecha)),
                    onTap: () => onDayTap(fecha),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}
