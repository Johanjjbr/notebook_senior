import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/enums.dart';
import '../models/recordatorio.dart';

class RecordatorioTile extends StatelessWidget {
  final Recordatorio recordatorio;
  final VoidCallback onEditar;
  final VoidCallback onCompletar;
  final VoidCallback onEliminar;

  const RecordatorioTile({
    super.key,
    required this.recordatorio,
    required this.onEditar,
    required this.onCompletar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final vencido = recordatorio.fechaHora.isBefore(DateTime.now()) &&
        !recordatorio.completado;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: recordatorio.completado
              ? Colors.green.withAlpha(30)
              : vencido
                  ? Colors.red.withAlpha(30)
                  : Colors.orange.withAlpha(30),
          child: Icon(
            recordatorio.completado ? Icons.check : Icons.alarm,
            color: recordatorio.completado
                ? Colors.green
                : vencido
                    ? Colors.red
                    : Colors.orange,
          ),
        ),
        title: Text(
          recordatorio.titulo,
          style: TextStyle(
            decoration: recordatorio.completado
                ? TextDecoration.lineThrough
                : null,
            color: recordatorio.completado ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('d MMM y - HH:mm').format(recordatorio.fechaHora)),
            if (recordatorio.recurrencia != Recurrencia.none)
              Row(
                children: [
                  Icon(Icons.repeat, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    recordatorio.recurrencia.label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'editar', child: Text('Editar')),
            if (!recordatorio.completado)
              const PopupMenuItem(value: 'completar', child: Text('Completar')),
            const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
          ],
          onSelected: (v) {
            if (v == 'editar') onEditar();
            if (v == 'completar') onCompletar();
            if (v == 'eliminar') onEliminar();
          },
        ),
      ),
    );
  }
}
