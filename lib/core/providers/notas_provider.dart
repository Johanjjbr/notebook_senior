import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/database_service.dart';
import '../../data/supabase_database_service.dart';
import '../../models/nota.dart';
import '../../models/categoria.dart';

class NotasProvider extends ChangeNotifier {
  final DatabaseService _db;
  final _uuid = const Uuid();
  static const _pageSize = 20;

  List<Nota> _notas = [];
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
  String? _error;

  NotasProvider({DatabaseService? db})
      : _db = db ?? SupabaseDatabaseService(Supabase.instance.client);

  List<Nota> get notas {
    if (_busqueda.isEmpty) return _notas;
    final query = _busqueda.toLowerCase();
    return _notas.where((n) =>
      n.titulo.toLowerCase().contains(query) ||
      n.contenido.toLowerCase().contains(query)
    ).toList();
  }

  List<Categoria> get categorias => _categorias;
  bool get cargandoLista => _cargandoLista;
  bool get cargandoMas => _cargandoMas;
  bool get guardando => _guardando;
  bool get eliminando => _eliminando;
  bool get hasMore => _hasMore;
  bool get cargando => _cargandoLista;
  String? get error => _error;

  void setBusqueda(String busqueda) {
    _busqueda = busqueda;
    notifyListeners();
  }

  void setSortField(String field) {
    _sortField = field;
    _sortAsc = field == 'titulo';
    cargarNotas();
  }

  Future<void> cargarNotas() async {
    _cargandoLista = true;
    _page = 0;
    _hasMore = true;
    _error = null;
    notifyListeners();

    try {
      _notas = await _db.cargarNotas(_sortField, _sortAsc, 0, _pageSize);
      _hasMore = _notas.length >= _pageSize;
    } catch (e) {
      _error = 'Error al cargar notas';
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
      final nuevos = await _db.cargarNotas(_sortField, _sortAsc, _page, _pageSize);
      _notas.addAll(nuevos);
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

  Future<void> crearNota(Nota nota, {List<String>? categoriaIds}) async {
    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      final notaJson = nota.copyWith(
        id: _uuid.v4(),
        userId: _db.userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _db.crearNota(notaJson);

      if (categoriaIds != null && categoriaIds.isNotEmpty) {
        await _db.insertarNotaCategorias(notaJson.id, categoriaIds);
      }

      await cargarNotas();
    } catch (e) {
      _error = 'Error al crear nota';
      notifyListeners();
    }

    _guardando = false;
    notifyListeners();
  }

  Future<void> actualizarNota(Nota nota, {List<String>? categoriaIds}) async {
    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      final updatedAt = DateTime.now();
      await _db.actualizarNota(nota.copyWith(updatedAt: updatedAt));

      if (categoriaIds != null) {
        await _db.eliminarNotaCategorias(nota.id);
        if (categoriaIds.isNotEmpty) {
          await _db.insertarNotaCategorias(nota.id, categoriaIds);
        }
      }

      await cargarNotas();
    } catch (e) {
      _error = 'Error al actualizar nota';
      notifyListeners();
    }

    _guardando = false;
    notifyListeners();
  }

  Future<void> archivarNota(String id) async {
    _error = null;
    try {
      await _db.archivarNota(id, true);
      await cargarNotas();
    } catch (e) {
      _error = 'Error al archivar nota';
      notifyListeners();
    }
  }

  Future<void> desarchivarNota(String id) async {
    _error = null;
    try {
      await _db.archivarNota(id, false);
      await cargarNotas();
    } catch (e) {
      _error = 'Error al restaurar nota';
      notifyListeners();
    }
  }

  Future<void> eliminarNota(String id) async {
    _eliminando = true;
    _error = null;
    notifyListeners();

    try {
      await _db.eliminarNota(id);
      await cargarNotas();
    } catch (e) {
      _error = 'Error al eliminar nota';
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
