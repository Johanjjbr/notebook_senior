enum Prioridad {
  baja,
  media,
  alta;

  String get label {
    switch (this) {
      case Prioridad.baja:
        return 'Baja';
      case Prioridad.media:
        return 'Media';
      case Prioridad.alta:
        return 'Alta';
    }
  }

  String toJson() => name;

  static Prioridad fromJson(String json) {
    return Prioridad.values.firstWhere(
      (e) => e.name == json,
      orElse: () => Prioridad.media,
    );
  }
}

enum TipoRecordatorio {
  nota,
  tarea,
  personalizado;

  String get label {
    switch (this) {
      case TipoRecordatorio.nota:
        return 'Nota';
      case TipoRecordatorio.tarea:
        return 'Tarea';
      case TipoRecordatorio.personalizado:
        return 'Personalizado';
    }
  }

  String toJson() => name;

  static TipoRecordatorio fromJson(String json) {
    return TipoRecordatorio.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TipoRecordatorio.personalizado,
    );
  }
}
