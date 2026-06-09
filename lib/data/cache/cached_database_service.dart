import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database_service.dart';
import '../supabase_database_service.dart';
import 'local_database.dart';
import '../../models/nota.dart';
import '../../models/tarea.dart';
import '../../models/recordatorio.dart';
import '../../models/categoria.dart';
import '../../models/checklist_item.dart';

class CachedDatabaseService implements DatabaseService {
  final SupabaseDatabaseService _remote;
  final LocalDatabase _local;
  final Connectivity _connectivity;

  CachedDatabaseService(this._remote, this._local, this._connectivity);

  Future<bool> get _isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  @override
  String get userId => _remote.userId;

  Future<List<T>> _withCache<T>({
    required Future<List<T>> Function() remoteCall,
    required Future<List<T>> Function() localCall,
    required Future<void> Function(List<T>) cacheUpdate,
  }) async {
    if (await _isOnline) {
      try {
        final data = await remoteCall();
        await cacheUpdate(data);
        return data;
      } catch (_) {
        return localCall();
      }
    }
    return localCall();
  }

  @override
  Future<List<Nota>> cargarNotas(String sortField, bool sortAsc, int page, int pageSize) async {
    return _withCache(
      remoteCall: () => _remote.cargarNotas(sortField, sortAsc, page, pageSize),
      localCall: () => _local.getNotas(),
      cacheUpdate: (data) => _local.cacheNotas(data),
    );
  }

  @override
  Future<void> crearNota(Nota nota) async {
    await _remote.crearNota(nota);
  }

  @override
  Future<void> actualizarNota(Nota nota) async {
    await _remote.actualizarNota(nota);
  }

  @override
  Future<void> archivarNota(String id, bool archivada) async {
    await _remote.archivarNota(id, archivada);
  }

  @override
  Future<void> eliminarNota(String id) async {
    await _remote.eliminarNota(id);
  }

  @override
  Future<void> insertarNotaCategorias(String notaId, List<String> categoriaIds) async {
    await _remote.insertarNotaCategorias(notaId, categoriaIds);
  }

  @override
  Future<void> eliminarNotaCategorias(String notaId) async {
    await _remote.eliminarNotaCategorias(notaId);
  }

  @override
  Future<List<Tarea>> cargarTareas(String sortField, bool sortAsc, int page, int pageSize) async {
    return _withCache(
      remoteCall: () => _remote.cargarTareas(sortField, sortAsc, page, pageSize),
      localCall: () => _local.getTareas(),
      cacheUpdate: (data) => _local.cacheTareas(data),
    );
  }

  @override
  Future<void> crearTarea(Tarea tarea) async {
    await _remote.crearTarea(tarea);
  }

  @override
  Future<void> actualizarTarea(Tarea tarea) async {
    await _remote.actualizarTarea(tarea);
  }

  @override
  Future<void> toggleTareaCompletada(String id, bool completada) async {
    await _remote.toggleTareaCompletada(id, completada);
  }

  @override
  Future<void> eliminarTarea(String id) async {
    await _remote.eliminarTarea(id);
  }

  @override
  Future<void> insertarTareaCategorias(String tareaId, List<String> categoriaIds) async {
    await _remote.insertarTareaCategorias(tareaId, categoriaIds);
  }

  @override
  Future<void> eliminarTareaCategorias(String tareaId) async {
    await _remote.eliminarTareaCategorias(tareaId);
  }

  @override
  Future<void> insertarChecklistItems(List<ChecklistItem> items, String tareaId) async {
    await _remote.insertarChecklistItems(items, tareaId);
  }

  @override
  Future<void> eliminarChecklistItems(String tareaId) async {
    await _remote.eliminarChecklistItems(tareaId);
  }

  @override
  Future<void> actualizarChecklistItem(String itemId, bool completada) async {
    await _remote.actualizarChecklistItem(itemId, completada);
  }

  @override
  Future<List<Categoria>> cargarCategorias() async {
    return _withCache(
      remoteCall: () => _remote.cargarCategorias(),
      localCall: () => _local.getCategorias(),
      cacheUpdate: (data) => _local.cacheCategorias(data),
    );
  }

  @override
  Future<void> crearCategoria(String nombre, String color) async {
    await _remote.crearCategoria(nombre, color);
  }

  @override
  Future<List<Recordatorio>> cargarRecordatorios(int page, int pageSize) async {
    return _withCache(
      remoteCall: () => _remote.cargarRecordatorios(page, pageSize),
      localCall: () => _local.getRecordatorios(),
      cacheUpdate: (data) => _local.cacheRecordatorios(data),
    );
  }

  @override
  Future<void> crearRecordatorio(Recordatorio recordatorio) async {
    await _remote.crearRecordatorio(recordatorio);
  }

  @override
  Future<void> actualizarRecordatorio(Recordatorio recordatorio) async {
    await _remote.actualizarRecordatorio(recordatorio);
  }

  @override
  Future<void> completarRecordatorio(String id) async {
    await _remote.completarRecordatorio(id);
  }

  @override
  Future<void> eliminarRecordatorio(String id) async {
    await _remote.eliminarRecordatorio(id);
  }
}
