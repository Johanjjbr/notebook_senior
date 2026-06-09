import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/database_service.dart';
import '../../data/supabase_database_service.dart';
import '../../models/nota.dart';
import '../../models/tarea.dart';
import '../../models/recordatorio.dart';
import '../services/notificacion_service.dart';

class CalendarioProvider extends ChangeNotifier {
  final DatabaseService _db;
  final _notificacionService = NotificacionService();
  final _uuid = const Uuid();

  DateTime _fechaEnfoque = DateTime.now();
  List<Nota> _notas = [];
  List<Tarea> _tareas = [];
  List<Recordatorio> _recordatorios = [];
  bool _cargandoLista = false;
  bool _guardando = false;
  bool _eliminando = false;
  String? _error;

  CalendarioProvider({DatabaseService? db})
      : _db = db ?? SupabaseDatabaseService(Supabase.instance.client);

  DateTime get fechaEnfoque => _fechaEnfoque;
  List<Nota> get notas => _notas;
  List<Tarea> get tareas => _tareas;
  List<Recordatorio> get recordatorios => _recordatorios;
  bool get cargandoLista => _cargandoLista;
  bool get guardando => _guardando;
  bool get eliminando => _eliminando;
  String? get error => _error;

  String get mesTitulo {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return '${meses[_fechaEnfoque.month - 1]} ${_fechaEnfoque.year}';
  }

  DateTime get primerDiaMes =>
      DateTime(_fechaEnfoque.year, _fechaEnfoque.month, 1);

  DateTime get ultimoDiaMes =>
      DateTime(_fechaEnfoque.year, _fechaEnfoque.month + 1, 0);

  int get diasEnMes => ultimoDiaMes.day;

  int get diaSemanaInicio => primerDiaMes.weekday % 7;

  DateTime get inicioRango =>
      primerDiaMes.subtract(Duration(days: diaSemanaInicio));

  DateTime get finRango =>
      ultimoDiaMes.add(Duration(days: 6 - ((diaSemanaInicio + diasEnMes - 1) % 7)));

  bool esMismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool tieneEventos(DateTime dia) =>
      _notas.any((n) => esMismoDia(n.createdAt, dia)) ||
      _tareas.any((t) =>
          t.fechaVencimiento != null && esMismoDia(t.fechaVencimiento!, dia)) ||
      _recordatorios.any((r) => esMismoDia(r.fechaHora, dia));

  List<dynamic> obtenerEventosDelDia(DateTime dia) {
    final eventos = <dynamic>[];
    eventos.addAll(_notas.where((n) => esMismoDia(n.createdAt, dia)));
    eventos.addAll(_tareas.where((t) =>
        t.fechaVencimiento != null && esMismoDia(t.fechaVencimiento!, dia)));
    eventos.addAll(
        _recordatorios.where((r) => esMismoDia(r.fechaHora, dia)));
    return eventos;
  }

  int get cantidadNotasMes => _notas.length;
  int get cantidadTareasMes =>
      _tareas.where((t) => !t.completada).length;
  int get cantidadRecordatoriosMes =>
      _recordatorios.where((r) => !r.completado).length;

  void irMesAnterior() {
    _fechaEnfoque = DateTime(_fechaEnfoque.year, _fechaEnfoque.month - 1, 1);
    cargarMes();
  }

  void irMesSiguiente() {
    _fechaEnfoque = DateTime(_fechaEnfoque.year, _fechaEnfoque.month + 1, 1);
    cargarMes();
  }

  void irAHoy() {
    _fechaEnfoque = DateTime.now();
    cargarMes();
  }

  Future<void> cargarMes() async {
    _cargandoLista = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _db.cargarNotasPorRango(inicioRango, finRango),
        _db.cargarTareasPorRango(inicioRango, finRango),
        _db.cargarRecordatoriosPorRango(inicioRango, finRango),
      ]);
      _notas = results[0] as List<Nota>;
      _tareas = results[1] as List<Tarea>;
      _recordatorios = results[2] as List<Recordatorio>;
    } catch (e) {
      _error = 'Error al cargar calendario';
    }

    _cargandoLista = false;
    notifyListeners();
  }

  Future<void> toggleTareaCompletada(String id, bool completada) async {
    _error = null;
    try {
      await _db.toggleTareaCompletada(id, completada);
      if (completada) {
        await _notificacionService.cancelarTarea(id);
      }
      await cargarMes();
    } catch (e) {
      _error = 'Error al actualizar tarea';
      notifyListeners();
    }
  }

  Future<void> completarRecordatorio(String id) async {
    _error = null;
    try {
      await _db.completarRecordatorio(id);
      await _notificacionService.cancelarRecordatorio(id);
      await cargarMes();
    } catch (e) {
      _error = 'Error al completar recordatorio';
      notifyListeners();
    }
  }

  Future<void> eliminarTarea(String id) async {
    _eliminando = true;
    _error = null;
    notifyListeners();

    try {
      await _notificacionService.cancelarTarea(id);
      await _db.eliminarTarea(id);
      await cargarMes();
    } catch (e) {
      _error = 'Error al eliminar tarea';
      notifyListeners();
    }

    _eliminando = false;
    notifyListeners();
  }

  Future<void> eliminarRecordatorio(String id) async {
    _eliminando = true;
    _error = null;
    notifyListeners();

    try {
      await _db.eliminarRecordatorio(id);
      await _notificacionService.cancelarRecordatorio(id);
      await cargarMes();
    } catch (e) {
      _error = 'Error al eliminar recordatorio';
      notifyListeners();
    }

    _eliminando = false;
    notifyListeners();
  }

  Future<void> eliminarNota(String id) async {
    _eliminando = true;
    _error = null;
    notifyListeners();

    try {
      await _db.eliminarNota(id);
      await cargarMes();
    } catch (e) {
      _error = 'Error al eliminar nota';
      notifyListeners();
    }

    _eliminando = false;
    notifyListeners();
  }

  Future<void> crearTareaRapida(
    String titulo,
    DateTime fechaVencimiento, {
    String descripcion = '',
  }) async {
    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      final tarea = Tarea(
        id: _uuid.v4(),
        userId: _db.userId,
        titulo: titulo,
        descripcion: descripcion,
        fechaVencimiento: fechaVencimiento,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _db.crearTarea(tarea);
      await _notificacionService.programarTarea(
        tarea.id, tarea.titulo, tarea.fechaVencimiento!,
      );
      await cargarMes();
    } catch (e) {
      _error = 'Error al crear tarea';
      notifyListeners();
    }

    _guardando = false;
    notifyListeners();
  }

  Future<void> crearRecordatorioRapido(
    String titulo,
    DateTime fechaHora, {
    String descripcion = '',
  }) async {
    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      final recordatorio = Recordatorio(
        id: _uuid.v4(),
        userId: _db.userId,
        titulo: titulo,
        descripcion: descripcion,
        fechaHora: fechaHora,
        createdAt: DateTime.now(),
      );
      await _db.crearRecordatorio(recordatorio);
      await _notificacionService.programarRecordatorio(recordatorio);
      await cargarMes();
    } catch (e) {
      _error = 'Error al crear recordatorio';
      notifyListeners();
    }

    _guardando = false;
    notifyListeners();
  }
}
