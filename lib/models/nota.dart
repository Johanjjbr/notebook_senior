import 'categoria.dart';

class Nota {
  final String id;
  final String userId;
  final String titulo;
  final String contenido;
  final String color;
  final bool archivada;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Categoria> categorias;

  const Nota({
    required this.id,
    required this.userId,
    this.titulo = '',
    this.contenido = '',
    this.color = '#FFF3CD',
    this.archivada = false,
    required this.createdAt,
    required this.updatedAt,
    this.categorias = const [],
  });

  factory Nota.fromJson(Map<String, dynamic> json) {
    return Nota(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      titulo: json['titulo'] as String? ?? '',
      contenido: json['contenido'] as String? ?? '',
      color: json['color'] as String? ?? '#FFF3CD',
      archivada: json['archivada'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
      'contenido': contenido,
      'color': color,
      'archivada': archivada,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Nota copyWith({
    String? id,
    String? userId,
    String? titulo,
    String? contenido,
    String? color,
    bool? archivada,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Categoria>? categorias,
  }) {
    return Nota(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      color: color ?? this.color,
      archivada: archivada ?? this.archivada,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categorias: categorias ?? this.categorias,
    );
  }
}
