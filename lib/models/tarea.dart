import 'enums.dart';
import 'categoria.dart';
import 'checklist_item.dart';

class Tarea {
  final String id;
  final String userId;
  final String titulo;
  final String descripcion;
  final bool completada;
  final Prioridad prioridad;
  final DateTime? fechaVencimiento;
  final String? notaId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChecklistItem> checklistItems;
  final List<Categoria> categorias;

  const Tarea({
    required this.id,
    required this.userId,
    required this.titulo,
    this.descripcion = '',
    this.completada = false,
    this.prioridad = Prioridad.media,
    this.fechaVencimiento,
    this.notaId,
    required this.createdAt,
    required this.updatedAt,
    this.checklistItems = const [],
    this.categorias = const [],
  });

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      completada: json['completada'] as bool? ?? false,
      prioridad: Prioridad.fromJson(json['prioridad'] as String? ?? 'media'),
      fechaVencimiento: json['fecha_vencimiento'] != null
          ? DateTime.parse(json['fecha_vencimiento'] as String)
          : null,
      notaId: json['nota_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      checklistItems: (json['checklist_items'] as List<dynamic>?)
              ?.map(
                  (e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      categorias: (json['categorias'] as List<dynamic>?)
              ?.map((e) => Categoria.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'titulo': titulo,
      'descripcion': descripcion,
      'completada': completada,
      'prioridad': prioridad.toJson(),
      'fecha_vencimiento': fechaVencimiento?.toIso8601String().split('T').first,
      'nota_id': notaId,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Tarea copyWith({
    String? id,
    String? userId,
    String? titulo,
    String? descripcion,
    bool? completada,
    Prioridad? prioridad,
    DateTime? fechaVencimiento,
    String? notaId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChecklistItem>? checklistItems,
    List<Categoria>? categorias,
  }) {
    return Tarea(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      completada: completada ?? this.completada,
      prioridad: prioridad ?? this.prioridad,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      notaId: notaId ?? this.notaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      checklistItems: checklistItems ?? this.checklistItems,
      categorias: categorias ?? this.categorias,
    );
  }
}
