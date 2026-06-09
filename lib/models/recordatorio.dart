import 'enums.dart';

class Recordatorio {
  final String id;
  final String userId;
  final String titulo;
  final String descripcion;
  final DateTime fechaHora;
  final TipoRecordatorio tipo;
  final String? referenciaId;
  final bool completado;
  final bool notificado;
  final Recurrencia recurrencia;
  final DateTime? recurrenciaFin;
  final DateTime createdAt;

  const Recordatorio({
    required this.id,
    required this.userId,
    required this.titulo,
    this.descripcion = '',
    required this.fechaHora,
    this.tipo = TipoRecordatorio.personalizado,
    this.referenciaId,
    this.completado = false,
    this.notificado = false,
    this.recurrencia = Recurrencia.none,
    this.recurrenciaFin,
    required this.createdAt,
  });

  factory Recordatorio.fromJson(Map<String, dynamic> json) {
    return Recordatorio(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      fechaHora: DateTime.parse(json['fecha_hora'] as String),
      tipo: TipoRecordatorio.fromJson(json['tipo'] as String? ?? 'personalizado'),
      referenciaId: json['referencia_id'] as String?,
      completado: json['completado'] as bool? ?? false,
      notificado: json['notificado'] as bool? ?? false,
      recurrencia: Recurrencia.fromJson(json['recurrencia'] as String? ?? 'none'),
      recurrenciaFin: json['recurrencia_fin'] != null
          ? DateTime.parse(json['recurrencia_fin'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_hora': fechaHora.toIso8601String(),
      'tipo': tipo.toJson(),
      'referencia_id': referenciaId,
      'completado': completado,
      'notificado': notificado,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Recordatorio copyWith({
    String? id,
    String? userId,
    String? titulo,
    String? descripcion,
    DateTime? fechaHora,
    TipoRecordatorio? tipo,
    String? referenciaId,
    bool? completado,
    bool? notificado,
    Recurrencia? recurrencia,
    DateTime? recurrenciaFin,
    DateTime? createdAt,
  }) {
    return Recordatorio(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fechaHora: fechaHora ?? this.fechaHora,
      tipo: tipo ?? this.tipo,
      referenciaId: referenciaId ?? this.referenciaId,
      completado: completado ?? this.completado,
      notificado: notificado ?? this.notificado,
      recurrencia: recurrencia ?? this.recurrencia,
      recurrenciaFin: recurrenciaFin ?? this.recurrenciaFin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
