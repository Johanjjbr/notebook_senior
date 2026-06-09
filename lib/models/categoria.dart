class Categoria {
  final String id;
  final String userId;
  final String nombre;
  final String color;

  const Categoria({
    required this.id,
    required this.userId,
    required this.nombre,
    this.color = '#6C3FAA',
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      nombre: json['nombre'] as String,
      color: json['color'] as String? ?? '#6C3FAA',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'nombre': nombre,
      'color': color,
    };
  }

  Categoria copyWith({
    String? id,
    String? userId,
    String? nombre,
    String? color,
  }) {
    return Categoria(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nombre: nombre ?? this.nombre,
      color: color ?? this.color,
    );
  }
}
