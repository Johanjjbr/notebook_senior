class ChecklistItem {
  final String id;
  final String tareaId;
  final String texto;
  final bool completada;
  final int orden;

  const ChecklistItem({
    required this.id,
    required this.tareaId,
    required this.texto,
    this.completada = false,
    this.orden = 0,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      tareaId: json['tarea_id'] as String,
      texto: json['texto'] as String,
      completada: json['completada'] as bool? ?? false,
      orden: json['orden'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'tarea_id': tareaId,
      'texto': texto,
      'completada': completada,
      'orden': orden,
    };
  }

  ChecklistItem copyWith({
    String? id,
    String? tareaId,
    String? texto,
    bool? completada,
    int? orden,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      tareaId: tareaId ?? this.tareaId,
      texto: texto ?? this.texto,
      completada: completada ?? this.completada,
      orden: orden ?? this.orden,
    );
  }
}
