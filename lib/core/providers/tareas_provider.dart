import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/database_service.dart';
import '../../data/supabase_database_service.dart';
import '../../models/tarea.dart';
import '../../models/checklist_item.dart';
import '../../models/categoria.dart';
import '../../models/enums.dart';
import '../services/notificacion_service.dart';

class TareasProvider extends ChangeNotifier {
  final DatabaseService _db;
  final _notificacionService = NotificacionService();
  final _uuid = const Uuid();
  static const _pageSize = 20;

  List<Tarea> _tareas = [];
  List<Categoria> _categorias = [];
  bool _cargandoLista = false;
  bool _cargandoMas = false;
  bool _guardando = false;
  bool _eliminando = false;
  bool _hasMore = true;
  int _page = 0;
  String _busqueda = '';
  String _sortField = 'updated_at';
  bool _sortAsc = false;
  String? _filtroEstado;
  Prioridad? _filtroPrioridad;
  bool _filtroProgramadas = false;
  String? _error;

  TareasProvider({DatabaseService? db})
      : _db = db ?? SupabaseDatabaseService(Supabase.instance.client);

  List<Tarea> get tareas {
    var result = _tareas;

    if (_busqueda.isNotEmpty) {
      final query = _busqueda.toLowerCase();
      result = result.where((t) =>
        t.titulo.toLowerCase().contains(query) ||
        t.descripcion.toLowerCase().contains(query)
      ).toList();
    }

    if (_filtroEstado == 'pendientes') {
      result = result.where((t) => !t.completada).toList();
    } else if (_filtroEstado == 'completadas') {
      result = result.where((t) => t.completada).toList();
    }

    if (_filtroPrioridad != null) {
      result = result.where((t) => t.prioridad == _filtroPrioridad).toList();
    }

    if (_filtroProgramadas) {
      result = result
          .where((t) => t.fechaVencimiento != null && !t.completada)
          .toList();
    }

    return result;
  }

  List<Categoria> get categorias => _categorias;
  bool get cargandoLista => _cargandoLista;
  bool get cargandoMas => _cargandoMas;
  bool get guardando => _guardando;
  bool get eliminando => _eliminando;
  bool get hasMore => _hasMore;
  bool get cargando => _cargandoLista;
  String? get error => _error;
  String? get filtroEstado => _filtroEstado;
  Prioridad? get filtroPrioridad => _filtroPrioridad;
  bool get filtroProgramadas => _filtroProgramadas;

  void setBusqueda(String busqueda) {
    _busqueda = busqueda;
    notifyListeners();
  }

  void setFiltroEstado(String? estado) {
    _filtroEstado = estado;
    notifyListeners();
  }

  void setFiltroPrioridad(Prioridad? prioridad) {
    _filtroPrioridad = prioridad;
    notifyListeners();
  }

  void setFiltroProgramadas(bool value) {
    _filtroProgramadas = value;
    notifyListeners();
  }

  void setSortField(String field) {
    _sortField = field;
    _sortAsc = field == 'titulo';
    cargarTareas();
  }

  Future<void> cargarTareas() async {
    _cargandoLista = true;
    _page = 0;
    _hasMore = true;
    _error = null;
    notifyListeners();

    try {
      _tareas = await _db.cargarTareas(_sortField, _sortAsc, 0, _pageSize);
      _hasMore = _tareas.length >= _pageSize;
    } catch (e) {
      _error = 'Error al cargar tareas';
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
      final nuevos = await _db.cargarTareas(_sortField, _sortAsc, _page, _pageSize);
      _tareas.addAll(nuevos);
      _hasMore = nuevos.length >= _pageSize;
    } catch (e) {
      _page--;
    }

    _cargandoMas = false;
    notifyListeners();
  }

  Future<void> cargarCategorias() async {
    _error = null;
    final anteriores = _categorias.length;
    try {
      _categorias = await _db.cargarCategorias();
    } catch (e) {
      _error = 'Error al cargar categorías';
    }
    if (_categorias.length != anteriores) {
      notifyListeners();
    }
  }

  Future<void> crearTarea(
    Tarea tarea, {
    List<ChecklistItem>? checklistItems,
    List<String>? categoriaIds,
  }) async {
    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      final tareaId = _uuid.v4();
      final now = DateTime.now();

      final tareaJson = tarea.copyWith(
        id: tareaId,
        userId: _db.userId,
        createdAt: now,
        updatedAt: now,
      );

      await _db.crearTarea(tareaJson);

      if (checklistItems != null && checklistItems.isNotEmpty) {
        await _db.insertarChecklistItems(checklistItems, tareaId);
      }

      if (categoriaIds != null && categoriaIds.isNotEmpty) {
        await _db.insertarTareaCategorias(tareaId, categoriaIds);
      }

      if (tarea.fechaVencimiento != null) {
        await _notificacionService.programarTarea(
          tareaId, tarea.titulo, tarea.fechaVencimiento!,
        );
      }

      await cargarTareas();
    } catch (e) {
      _error = 'Error al crear tarea';
      notifyListeners();
    }

    _guardando = false;
    notifyListeners();
  }

  Future<void> actualizarTarea(
    Tarea tarea, {
    List<ChecklistItem>? checklistItems,
    List<String>? categoriaIds,
  }) async {
    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      final updatedAt = DateTime.now();
      await _db.actualizarTarea(tarea.copyWith(updatedAt: updatedAt));

      if (checklistItems != null) {
        await _db.eliminarChecklistItems(tarea.id);
        if (checklistItems.isNotEmpty) {
          final itemsConEstado = checklistItems.map((item) {
            final original = _tareas
                .expand((t) => t.checklistItems)
                .where((i) => i.texto == item.texto)
                .firstOrNull;
            return ChecklistItem(
              id: original?.id ?? item.id,
              tareaId: tarea.id,
              texto: item.texto,
              completada: original?.completada ?? item.completada,
              orden: item.orden,
            );
          }).toList();
          await _db.insertarChecklistItems(itemsConEstado, tarea.id);
        }
      }

      if (categoriaIds != null) {
        await _db.eliminarTareaCategorias(tarea.id);
        if (categoriaIds.isNotEmpty) {
          await _db.insertarTareaCategorias(tarea.id, categoriaIds);
        }
      }

      await _notificacionService.cancelarTarea(tarea.id);
      if (tarea.fechaVencimiento != null && !tarea.completada) {
        await _notificacionService.programarTarea(
          tarea.id, tarea.titulo, tarea.fechaVencimiento!,
        );
      }

      await cargarTareas();
    } catch (e) {
      _error = 'Error al actualizar tarea';
      notifyListeners();
    }

    _guardando = false;
    notifyListeners();
  }

  Future<void> toggleCompletada(String id, bool completada) async {
    _error = null;
    try {
      await _db.toggleTareaCompletada(id, completada);

      if (completada) {
        await _notificacionService.cancelarTarea(id);
      }

      await cargarTareas();
    } catch (e) {
      _error = 'Error al actualizar tarea';
      notifyListeners();
    }
  }

  Future<void> toggleChecklistItem(
      String itemId, String tareaId, bool completada) async {
    _error = null;
    try {
      await _db.actualizarChecklistItem(itemId, completada);
      await cargarTareas();
    } catch (e) {
      _error = 'Error al actualizar checklist';
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
      await cargarTareas();
    } catch (e) {
      _error = 'Error al eliminar tarea';
      notifyListeners();
    }

    _eliminando = false;
    notifyListeners();
  }

  Future<void> crearCategoria(String nombre, String color) async {
    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      await _db.crearCategoria(nombre, color);
      await cargarCategorias();
    } catch (e) {
      _error = 'Error al crear categoría';
      notifyListeners();
    }

    _guardando = false;
    notifyListeners();
  }
}
