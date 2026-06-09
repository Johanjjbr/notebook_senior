import '../models/checklist_item.dart';
import '../models/nota.dart';
import '../models/categoria.dart';
import '../models/tarea.dart';
import '../models/recordatorio.dart';

abstract class DatabaseService {
  String get userId;

  Future<List<Nota>> cargarNotas(String sortField, bool sortAsc, int page, int pageSize);
  Future<void> crearNota(Nota nota);
  Future<void> actualizarNota(Nota nota);
  Future<void> archivarNota(String id, bool archivada);
  Future<void> eliminarNota(String id);
  Future<void> insertarNotaCategorias(String notaId, List<String> categoriaIds);
  Future<void> eliminarNotaCategorias(String notaId);

  Future<List<Tarea>> cargarTareas(String sortField, bool sortAsc, int page, int pageSize);
  Future<void> crearTarea(Tarea tarea);
  Future<void> actualizarTarea(Tarea tarea);
  Future<void> toggleTareaCompletada(String id, bool completada);
  Future<void> eliminarTarea(String id);
  Future<void> insertarTareaCategorias(String tareaId, List<String> categoriaIds);
  Future<void> eliminarTareaCategorias(String tareaId);
  Future<void> insertarChecklistItems(List<ChecklistItem> items, String tareaId);
  Future<void> eliminarChecklistItems(String tareaId);
  Future<void> actualizarChecklistItem(String itemId, bool completada);

  Future<List<Categoria>> cargarCategorias();
  Future<void> crearCategoria(String nombre, String color);

  Future<List<Recordatorio>> cargarRecordatorios(int page, int pageSize);
  Future<void> crearRecordatorio(Recordatorio recordatorio);
  Future<void> actualizarRecordatorio(Recordatorio recordatorio);
  Future<void> completarRecordatorio(String id);
  Future<void> eliminarRecordatorio(String id);
}
