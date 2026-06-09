import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';
import '../models/checklist_item.dart';
import '../models/nota.dart';
import '../models/categoria.dart';
import '../models/tarea.dart';
import '../models/recordatorio.dart';

class SupabaseDatabaseService implements DatabaseService {
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  SupabaseDatabaseService(this._supabase);

  @override
  String get userId => _supabase.auth.currentUser!.id;

  @override
  Future<List<Nota>> cargarNotas(String sortField, bool sortAsc, int page, int pageSize) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final response = await _supabase
        .from('notas')
        .select('*, categorias:nota_categorias(categoria_id, categorias(*))')
        .eq('user_id', userId)
        .order(sortField, ascending: sortAsc)
        .range(from, to);

    return (response as List).map((json) {
      final categorias = (json['categorias'] as List<dynamic>?)
              ?.map((e) => Categoria.fromJson(
                  (e as Map<String, dynamic>)['categorias'] as Map<String, dynamic>))
              .toList() ??
          [];
      return Nota.fromJson(json).copyWith(categorias: categorias);
    }).toList();
  }

  @override
  Future<void> crearNota(Nota nota) async {
    await _supabase.from('notas').insert(nota.toJson());
  }

  @override
  Future<void> actualizarNota(Nota nota) async {
    await _supabase.from('notas').update(nota.toJson()).eq('id', nota.id);
  }

  @override
  Future<void> archivarNota(String id, bool archivada) async {
    await _supabase.from('notas').update({
      'archivada': archivada,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> eliminarNota(String id) async {
    await _supabase.from('notas').delete().eq('id', id);
  }

  @override
  Future<void> insertarNotaCategorias(String notaId, List<String> categoriaIds) async {
    for (final catId in categoriaIds) {
      await _supabase.from('nota_categorias').insert({
        'nota_id': notaId,
        'categoria_id': catId,
      });
    }
  }

  @override
  Future<void> eliminarNotaCategorias(String notaId) async {
    await _supabase.from('nota_categorias').delete().eq('nota_id', notaId);
  }

  @override
  Future<List<Tarea>> cargarTareas(String sortField, bool sortAsc, int page, int pageSize) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final response = await _supabase
        .from('tareas')
        .select('*, checklist_items(*), categorias:tarea_categorias(categoria_id, categorias(*))')
        .eq('user_id', userId)
        .order(sortField, ascending: sortAsc)
        .range(from, to);

    return (response as List).map((json) {
      final checklistItems = (json['checklist_items'] as List<dynamic>?)
              ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final categorias = (json['categorias'] as List<dynamic>?)
              ?.map((e) => Categoria.fromJson(
                  (e as Map<String, dynamic>)['categorias'] as Map<String, dynamic>))
              .toList() ??
          [];
      return Tarea.fromJson(json).copyWith(
        checklistItems: checklistItems,
        categorias: categorias,
      );
    }).toList();
  }

  @override
  Future<void> crearTarea(Tarea tarea) async {
    await _supabase.from('tareas').insert(tarea.toJson());
  }

  @override
  Future<void> actualizarTarea(Tarea tarea) async {
    await _supabase.from('tareas').update(tarea.toJson()).eq('id', tarea.id);
  }

  @override
  Future<void> toggleTareaCompletada(String id, bool completada) async {
    await _supabase.from('tareas').update({
      'completada': completada,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> eliminarTarea(String id) async {
    await _supabase.from('tareas').delete().eq('id', id);
  }

  @override
  Future<void> insertarTareaCategorias(String tareaId, List<String> categoriaIds) async {
    for (final catId in categoriaIds) {
      await _supabase.from('tarea_categorias').insert({
        'tarea_id': tareaId,
        'categoria_id': catId,
      });
    }
  }

  @override
  Future<void> eliminarTareaCategorias(String tareaId) async {
    await _supabase.from('tarea_categorias').delete().eq('tarea_id', tareaId);
  }

  @override
  Future<void> insertarChecklistItems(List<ChecklistItem> items, String tareaId) async {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      await _supabase.from('checklist_items').insert({
        'id': item.id.isNotEmpty ? item.id : _uuid.v4(),
        'tarea_id': tareaId,
        'texto': item.texto,
        'completada': item.completada,
        'orden': i,
      });
    }
  }

  @override
  Future<void> eliminarChecklistItems(String tareaId) async {
    await _supabase.from('checklist_items').delete().eq('tarea_id', tareaId);
  }

  @override
  Future<void> actualizarChecklistItem(String itemId, bool completada) async {
    await _supabase.from('checklist_items').update({'completada': completada}).eq('id', itemId);
  }

  @override
  Future<List<Categoria>> cargarCategorias() async {
    final response = await _supabase
        .from('categorias')
        .select()
        .eq('user_id', userId)
        .order('nombre');
    return (response as List)
        .map((json) => Categoria.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> crearCategoria(String nombre, String color) async {
    await _supabase.from('categorias').insert({
      'id': _uuid.v4(),
      'user_id': userId,
      'nombre': nombre,
      'color': color,
    });
  }

  @override
  Future<List<Recordatorio>> cargarRecordatorios(int page, int pageSize) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final response = await _supabase
        .from('recordatorios')
        .select()
        .eq('user_id', userId)
        .order('fecha_hora', ascending: true)
        .range(from, to);
    return (response as List)
        .map((json) => Recordatorio.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> crearRecordatorio(Recordatorio recordatorio) async {
    await _supabase.from('recordatorios').insert(recordatorio.toJson());
  }

  @override
  Future<void> actualizarRecordatorio(Recordatorio recordatorio) async {
    await _supabase.from('recordatorios').update(recordatorio.toJson()).eq('id', recordatorio.id);
  }

  @override
  Future<void> completarRecordatorio(String id) async {
    await _supabase.from('recordatorios').update({'completado': true}).eq('id', id);
  }

  @override
  Future<void> eliminarRecordatorio(String id) async {
    await _supabase.from('recordatorios').delete().eq('id', id);
  }
}
