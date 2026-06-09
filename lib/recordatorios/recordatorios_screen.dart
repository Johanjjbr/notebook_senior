import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/providers/recordatorios_provider.dart';
import '../models/recordatorio.dart';

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
    final tituloCtrl = TextEditingController(text: existente?.titulo);
    final descCtrl = TextEditingController(text: existente?.descripcion);
    DateTime fechaHora = existente?.fechaHora ?? DateTime.now().add(const Duration(hours: 1));
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
                      esEdicion ? 'Editar recordatorio' : 'Nuevo recordatorio',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: tituloCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Título'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Obligatorio' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title:
                          Text(DateFormat('d MMM y').format(fechaHora)),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: fechaHora,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setSheetState(() {
                            fechaHora = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              fechaHora.hour,
                              fechaHora.minute,
                            );
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
                          initialTime:
                              TimeOfDay.fromDateTime(fechaHora),
                        );
                        if (time != null) {
                          setSheetState(() {
                            fechaHora = DateTime(
                              fechaHora.year,
                              fechaHora.month,
                              fechaHora.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final provider = context
                              .read<RecordatoriosProvider>();
                          if (esEdicion) {
                            await provider.actualizarRecordatorio(
                              existente.copyWith(
                                titulo: tituloCtrl.text.trim(),
                                descripcion: descCtrl.text.trim(),
                                fechaHora: fechaHora,
                              ),
                            );
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Recordatorio actualizado')),
                              );
                            }
                          } else {
                            await provider.crearRecordatorio(Recordatorio(
                              id: '',
                              userId: '',
                              titulo: tituloCtrl.text.trim(),
                              descripcion: descCtrl.text.trim(),
                              fechaHora: fechaHora,
                              createdAt: DateTime.now(),
                            ));
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Recordatorio creado')),
                              );
                            }
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child:
                            const Text('Guardar recordatorio'),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecordatoriosProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
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
              ? const Center(child: CircularProgressIndicator())
              : provider.recordatorios.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.alarm_outlined,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Sin recordatorios',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  )
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      children: [
                        if (provider.proximos.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('Próximos',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                )),
                          ),
                          ...provider.proximos.map((r) =>
                              _RecordatorioTile(
                                recordatorio: r,
                                onEditar: () => _mostrarDialogo(existente: r),
                                onCompletar: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  await provider.completarRecordatorio(r.id);
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Recordatorio completado')),
                                  );
                                },
                                onEliminar: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  await provider.eliminarRecordatorio(r.id);
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Recordatorio eliminado')),
                                  );
                                },
                              )),
                          const SizedBox(height: 16),
                        ],
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Todos',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        ...provider.recordatorios.map((r) =>
                            _RecordatorioTile(
                              recordatorio: r,
                              onEditar: () => _mostrarDialogo(existente: r),
                              onCompletar: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await provider.completarRecordatorio(r.id);
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Recordatorio completado')),
                                );
                              },
                              onEliminar: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await provider.eliminarRecordatorio(r.id);
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Recordatorio eliminado')),
                                );
                              },
                            )),
                      ],
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

class _RecordatorioTile extends StatelessWidget {
  final Recordatorio recordatorio;
  final VoidCallback onEditar;
  final VoidCallback onCompletar;
  final VoidCallback onEliminar;

  const _RecordatorioTile({
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
            color:
                recordatorio.completado ? Colors.grey : null,
          ),
        ),
        subtitle: Text(DateFormat('d MMM y - HH:mm')
            .format(recordatorio.fechaHora)),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'editar', child: Text('Editar')),
            if (!recordatorio.completado)
              const PopupMenuItem(
                  value: 'completar', child: Text('Completar')),
            const PopupMenuItem(
                value: 'eliminar', child: Text('Eliminar')),
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
