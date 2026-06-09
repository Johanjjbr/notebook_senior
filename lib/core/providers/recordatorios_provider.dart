import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/database_service.dart';
import '../../data/supabase_database_service.dart';
import '../../models/recordatorio.dart';
import '../services/notificacion_service.dart';

class RecordatoriosProvider extends ChangeNotifier {
  final DatabaseService _db;
  final SupabaseClient? _supabase;
  final _uuid = const Uuid();
  final _notificacionService = NotificacionService();
  static const _pageSize = 20;

  RealtimeChannel? _subscriptionRecordatorios;

  List<Recordatorio> _recordatorios = [];
  bool _cargandoLista = false;
  bool _cargandoMas = false;
  bool _guardando = false;
  bool _eliminando = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;
  Recordatorio? _ultimoRecordatorioEliminado;

  RecordatoriosProvider({DatabaseService? db})
      : _db = db ?? SupabaseDatabaseService(Supabase.instance.client),
        _supabase = db == null ? Supabase.instance.client : null;

  @override
  void dispose() {
    _subscriptionRecordatorios?.unsubscribe();
    super.dispose();
  }

  void _suscribirCambios() {
    final supabase = _supabase;
    if (supabase == null) return;
    _subscriptionRecordatorios?.unsubscribe();
    _subscriptionRecordatorios = supabase
        .channel('recordatorios-cambios')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'recordatorios',
          callback: (_) => cargarRecordatorios(),
        )
        .subscribe();
  }

  List<Recordatorio> get recordatorios => _recordatorios;
  List<Recordatorio> get proximos {
    final now = DateTime.now();
    return _recordatorios
        .where((r) => !r.completado && r.fechaHora.isAfter(now))
        .toList()
      ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
  }

  bool get cargandoLista => _cargandoLista;
  bool get cargandoMas => _cargandoMas;
  bool get guardando => _guardando;
  bool get eliminando => _eliminando;
  bool get hasMore => _hasMore;
  bool get cargando => _cargandoLista;
  String? get error => _error;

  Future<void> cargarRecordatorios() async {
    _cargandoLista = true;
    _page = 0;
    _hasMore = true;
    _error = null;
    notifyListeners();

    try {
      _recordatorios = await _db.cargarRecordatorios(0, _pageSize);
      _hasMore = _recordatorios.length >= _pageSize;
      _suscribirCambios();
    } catch (e) {
      _error = 'Error al cargar recordatorios';
    }

    _cargandoLista = false;
    notifyListeners();
  }

  Future<void> cargarMas() async {
    if (_cargandoMas || !_hasMore) return;
    _cargandoMas = true;
    notifyListeners();

    try {
      _page++;
      final nuevos = await _db.cargarRecordatorios(_page, _pageSize);
      _recordatorios.addAll(nuevos);
      _hasMore = nuevos.length >= _pageSize;
    } catch (e) {
      _page--;
    }

    _cargandoMas = false;
    notifyListeners();
  }

  Future<void> crearRecordatorio(Recordatorio recordatorio) async {
    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      final nuevo = recordatorio.copyWith(
        id: _uuid.v4(),
        userId: _db.userId,
        createdAt: DateTime.now(),
      );

      await _db.crearRecordatorio(nuevo);
      await _notificacionService.programarRecordatorio(nuevo);
      await cargarRecordatorios();
    } catch (e) {
      _error = 'Error al crear recordatorio';
      notifyListeners();
    }

    _guardando = false;
    notifyListeners();
  }

  Future<void> actualizarRecordatorio(Recordatorio recordatorio) async {
    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      await _db.actualizarRecordatorio(recordatorio);

      await _notificacionService.cancelarRecordatorio(recordatorio.id);
      if (!recordatorio.completado) {
        await _notificacionService.programarRecordatorio(recordatorio);
      }

      await cargarRecordatorios();
    } catch (e) {
      _error = 'Error al actualizar recordatorio';
      notifyListeners();
    }

    _guardando = false;
    notifyListeners();
  }

  Future<void> completarRecordatorio(String id) async {
    _error = null;
    try {
      await _db.completarRecordatorio(id);
      await _notificacionService.cancelarRecordatorio(id);
      await cargarRecordatorios();
    } catch (e) {
      _error = 'Error al completar recordatorio';
      notifyListeners();
    }
  }

  Future<void> eliminarRecordatorio(String id) async {
    _eliminando = true;
    _error = null;
    _ultimoRecordatorioEliminado =
        _recordatorios.where((r) => r.id == id).firstOrNull;
    notifyListeners();

    try {
      await _db.eliminarRecordatorio(id);
      await _notificacionService.cancelarRecordatorio(id);
      await cargarRecordatorios();
    } catch (e) {
      _error = 'Error al eliminar recordatorio';
      _ultimoRecordatorioEliminado = null;
      notifyListeners();
    }

    _eliminando = false;
    notifyListeners();
  }

  Future<void> restaurarUltimoRecordatorio() async {
    final recordatorio = _ultimoRecordatorioEliminado;
    if (recordatorio == null) return;
    _ultimoRecordatorioEliminado = null;

    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      await _db.crearRecordatorio(recordatorio);
      if (!recordatorio.completado &&
          recordatorio.fechaHora.isAfter(DateTime.now())) {
        await _notificacionService.programarRecordatorio(recordatorio);
      }
      await cargarRecordatorios();
    } catch (e) {
      _error = 'Error al restaurar recordatorio';
      notifyListeners();
    }

    _guardando = false;
    notifyListeners();
  }

  Future<void> reprogramarPendientes() async {
    try {
      final now = DateTime.now();
      for (final r in _recordatorios) {
        if (!r.completado && !r.notificado && r.fechaHora.isAfter(now)) {
          await _notificacionService.programarRecordatorio(r);
        }
      }
    } catch (e) {
      _error = 'Error al reprogramar recordatorios';
      notifyListeners();
    }
  }
}
