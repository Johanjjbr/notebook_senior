import 'package:flutter/material.dart';

class DayCell extends StatelessWidget {
  final int? dia;
  final bool esHoy;
  final bool esMesActual;
  final bool tieneNotas;
  final bool tieneTareas;
  final bool tieneRecordatorios;
  final VoidCallback? onTap;

  const DayCell({
    super.key,
    this.dia,
    this.esHoy = false,
    this.esMesActual = true,
    this.tieneNotas = false,
    this.tieneTareas = false,
    this.tieneRecordatorios = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (dia == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: esHoy
              ? colorScheme.primaryContainer.withAlpha(180)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dia.toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: esHoy ? FontWeight.bold : FontWeight.normal,
                color: esHoy
                    ? colorScheme.onPrimaryContainer
                    : esMesActual
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withAlpha(100),
              ),
            ),
            const SizedBox(height: 2),
            if (tieneNotas || tieneTareas || tieneRecordatorios)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (tieneNotas)
                    _dot(colorScheme.primary, 4),
                  if (tieneTareas)
                    _dot(Colors.blue, 4),
                  if (tieneRecordatorios)
                    _dot(Colors.orange, 4),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
