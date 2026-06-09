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

enum Recurrencia {
  none,
  diaria,
  semanal,
  mensual,
  anual;

  String get label {
    switch (this) {
      case Recurrencia.none:
        return 'No repetir';
      case Recurrencia.diaria:
        return 'Diaria';
      case Recurrencia.semanal:
        return 'Semanal';
      case Recurrencia.mensual:
        return 'Mensual';
      case Recurrencia.anual:
        return 'Anual';
    }
  }

  String toJson() => name;

  static Recurrencia fromJson(String json) {
    return Recurrencia.values.firstWhere(
      (e) => e.name == json,
      orElse: () => Recurrencia.none,
    );
  }

  DateTime nextDate(DateTime from) {
    switch (this) {
      case Recurrencia.none:
        return from;
      case Recurrencia.diaria:
        return from.add(const Duration(days: 1));
      case Recurrencia.semanal:
        return from.add(const Duration(days: 7));
      case Recurrencia.mensual:
        return DateTime(from.year, from.month + 1, from.day);
      case Recurrencia.anual:
        return DateTime(from.year + 1, from.month, from.day);
    }
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
