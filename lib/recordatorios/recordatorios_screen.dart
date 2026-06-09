import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/providers/recordatorios_provider.dart';
import '../models/recordatorio.dart';
import '../models/enums.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/recordatorio_tile.dart';
import '../l10n/app_localizations.dart';

class RecordatoriosScreen extends StatefulWidget {
  const RecordatoriosScreen({super.key});

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordatoriosProvider>().cargarRecordatorios();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<RecordatoriosProvider>().cargarMas();
    }
  }

  void _mostrarDialogo({Recordatorio? existente}) {
    final l10n = AppLocalizations.of(context)!;
    final tituloCtrl = TextEditingController(text: existente?.titulo);
    final descCtrl = TextEditingController(text: existente?.descripcion);
    DateTime fechaHora = existente?.fechaHora ?? DateTime.now().add(const Duration(hours: 1));
    Recurrencia recurrencia = existente?.recurrencia ?? Recurrencia.none;
    DateTime? recurrenciaFin = existente?.recurrenciaFin;
    final formKey = GlobalKey<FormState>();
    final esEdicion = existente != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      esEdicion ? l10n.editReminder : l10n.newReminder,
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: tituloCtrl,
                      decoration: InputDecoration(labelText: l10n.reminderTitle),
                      validator: (v) => v == null || v.isEmpty ? l10n.required : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: InputDecoration(labelText: l10n.reminderDescription),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: Text(DateFormat('d MMM y').format(fechaHora)),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: fechaHora,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setSheetState(() {
                            fechaHora = DateTime(date.year, date.month, date.day, fechaHora.hour, fechaHora.minute);
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(DateFormat('HH:mm').format(fechaHora)),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.fromDateTime(fechaHora),
                        );
                        if (time != null) {
                          setSheetState(() {
                            fechaHora = DateTime(fechaHora.year, fechaHora.month, fechaHora.day, time.hour, time.minute);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('Repetir', style: Theme.of(ctx).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _RecurrenciaSelector(
                      value: recurrencia,
                      onChanged: (v) => setSheetState(() => recurrencia = v),
                    ),
                    if (recurrencia != Recurrencia.none) ...[
                      const SizedBox(height: 8),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.event),
                        title: Text(
                          recurrenciaFin != null
                              ? 'Hasta ${DateFormat('d MMM y').format(recurrenciaFin!)}'
                              : 'Sin fecha de fin',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (recurrenciaFin != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () => setSheetState(() => recurrenciaFin = null),
                              ),
                            IconButton(
                              icon: const Icon(Icons.calendar_month, size: 20),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: ctx,
                                  initialDate: recurrenciaFin ?? fechaHora.add(const Duration(days: 30)),
                                  firstDate: fechaHora,
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                );
                                if (date != null) setSheetState(() => recurrenciaFin = date);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final provider = context.read<RecordatoriosProvider>();
                          if (esEdicion) {
                            await provider.actualizarRecordatorio(
                              existente.copyWith(
                                titulo: tituloCtrl.text.trim(),
                                descripcion: descCtrl.text.trim(),
                                fechaHora: fechaHora,
                                recurrencia: recurrencia,
                                recurrenciaFin: recurrenciaFin,
                              ),
                            );
                            if (ctx.mounted) {
                              final l10n = AppLocalizations.of(ctx)!;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(l10n.reminderUpdated)),
                              );
                            }
                          } else {
                            await provider.crearRecordatorio(Recordatorio(
                              id: '',
                              userId: '',
                              titulo: tituloCtrl.text.trim(),
                              descripcion: descCtrl.text.trim(),
                              fechaHora: fechaHora,
                              recurrencia: recurrencia,
                              recurrenciaFin: recurrenciaFin,
                              createdAt: DateTime.now(),
                            ));
                            if (ctx.mounted) {
                              final l10n = AppLocalizations.of(ctx)!;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(l10n.reminderCreated)),
                              );
                            }
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Text(l10n.saveReminder),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completar(Recordatorio r) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await context.read<RecordatoriosProvider>().completarRecordatorio(r.id);
    if (mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.reminderCompleted)));
    }
  }

  Future<void> _eliminar(Recordatorio r) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<RecordatoriosProvider>();
    await provider.eliminarRecordatorio(r.id);
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.reminderDeleted),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => context.read<RecordatoriosProvider>().restaurarUltimoRecordatorio(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<RecordatoriosProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.remindersTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm),
            onPressed: () => _mostrarDialogo(),
          ),
        ],
      ),
      body: Stack(
        children: [
          provider.cargando
              ? const ShimmerList()
              : provider.recordatorios.isEmpty
                  ? EmptyState(
                      icon: Icons.alarm_outlined,
                      title: l10n.noReminders,
                      subtitle: l10n.createReminderHint,
                      actionLabel: l10n.createReminder,
                      actionIcon: Icons.add_alarm,
                      onAction: () => _mostrarDialogo(),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.cargarRecordatorios(),
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        children: [
                          if (provider.proximos.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(l10n.upcoming,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  )),
                            ),
                            ...provider.proximos.map((r) => Dismissible(
                              key: ValueKey('prox-${r.id}'),
                              direction: DismissDirection.horizontal,
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.check, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  final l10n = AppLocalizations.of(context)!;
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(l10n.deleteReminder),
                                      content: Text(l10n.deleteConfirm),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _eliminar(r);
                                  }
                                  return confirm == true;
                                }
                                await _completar(r);
                                return true;
                              },
                              child: RecordatorioTile(
                                recordatorio: r,
                                onEditar: () => _mostrarDialogo(existente: r),
                                onCompletar: () => _completar(r),
                                onEliminar: () => _eliminar(r),
                              ),
                            )),
                            const SizedBox(height: 16),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(l10n.all,
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold)),
                          ),
                          ...provider.recordatorios.map((r) => Dismissible(
                            key: ValueKey('all-${r.id}'),
                            direction: DismissDirection.horizontal,
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.check, color: Colors.white),
                            ),
                            secondaryBackground: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                final l10n = AppLocalizations.of(context)!;
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(l10n.deleteReminder),
                                    content: Text(l10n.deleteConfirm),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _eliminar(r);
                                }
                                return confirm == true;
                              }
                              await _completar(r);
                              return true;
                            },
                            child: RecordatorioTile(
                              recordatorio: r,
                              onEditar: () => _mostrarDialogo(existente: r),
                              onCompletar: () => _completar(r),
                              onEliminar: () => _eliminar(r),
                            ),
                          )),
                        ],
                      ),
                    ),
          if (provider.cargandoMas)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogo(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RecurrenciaSelector extends StatelessWidget {
  final Recurrencia value;
  final ValueChanged<Recurrencia> onChanged;

  const _RecurrenciaSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: Recurrencia.values.map((r) {
          final selected = value == r;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(r.label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
              selected: selected,
              selectedColor: Theme.of(context).colorScheme.primary,
              onSelected: (_) => onChanged(r),
            ),
          );
        }).toList(),
      ),
    );
  }
}
