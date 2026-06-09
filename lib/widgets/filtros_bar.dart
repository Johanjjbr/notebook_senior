import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../core/theme/app_theme.dart';

class FiltrosBar extends StatelessWidget {
  final String? filtroEstado;
  final bool filtroProgramadas;
  final Prioridad? filtroPrioridad;
  final ValueChanged<String?> onChangedEstado;
  final ValueChanged<bool> onChangedProgramadas;
  final ValueChanged<Prioridad?> onChangedPrioridad;

  const FiltrosBar({
    super.key,
    required this.filtroEstado,
    required this.filtroProgramadas,
    required this.filtroPrioridad,
    required this.onChangedEstado,
    required this.onChangedProgramadas,
    required this.onChangedPrioridad,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _FiltroChip(
            label: 'Todas',
            selected: filtroEstado == null,
            onSelected: () => onChangedEstado(null),
          ),
          _FiltroChip(
            label: 'Pendientes',
            selected: filtroEstado == 'pendientes',
            onSelected: () => onChangedEstado('pendientes'),
          ),
          _FiltroChip(
            label: 'Completadas',
            selected: filtroEstado == 'completadas',
            onSelected: () => onChangedEstado('completadas'),
          ),
          _FiltroChip(
            label: 'Programadas',
            selected: filtroProgramadas,
            onSelected: () => onChangedProgramadas(!filtroProgramadas),
          ),
          _PrioridadChip(
            prioridad: Prioridad.alta,
            selected: filtroPrioridad == Prioridad.alta,
            onSelected: () => onChangedPrioridad(
              filtroPrioridad == Prioridad.alta ? null : Prioridad.alta,
            ),
          ),
          _PrioridadChip(
            prioridad: Prioridad.media,
            selected: filtroPrioridad == Prioridad.media,
            onSelected: () => onChangedPrioridad(
              filtroPrioridad == Prioridad.media ? null : Prioridad.media,
            ),
          ),
          _PrioridadChip(
            prioridad: Prioridad.baja,
            selected: filtroPrioridad == Prioridad.baja,
            onSelected: () => onChangedPrioridad(
              filtroPrioridad == Prioridad.baja ? null : Prioridad.baja,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _PrioridadChip extends StatelessWidget {
  final Prioridad prioridad;
  final bool selected;
  final VoidCallback onSelected;

  const _PrioridadChip({
    required this.prioridad,
    required this.selected,
    required this.onSelected,
  });

  Color get _color {
    switch (prioridad) {
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
    return FilterChip(
      label: Text(prioridad.label,
          style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
      selected: selected,
      selectedColor: _color,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
    );
  }
}
