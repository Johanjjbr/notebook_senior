-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- NOTAS
CREATE TABLE notas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  titulo TEXT NOT NULL DEFAULT '',
  contenido TEXT NOT NULL DEFAULT '',
  color TEXT NOT NULL DEFAULT '#FFF3CD',
  archivada BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- CATEGORIAS (etiquetas)
CREATE TABLE categorias (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  nombre TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#6C3FAA',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RELACION NOTA-CATEGORIA
CREATE TABLE nota_categorias (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nota_id UUID REFERENCES notas(id) ON DELETE CASCADE,
  categoria_id UUID REFERENCES categorias(id) ON DELETE CASCADE,
  UNIQUE(nota_id, categoria_id)
);

-- TAREAS
CREATE TABLE tareas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  titulo TEXT NOT NULL,
  descripcion TEXT NOT NULL DEFAULT '',
  completada BOOLEAN NOT NULL DEFAULT false,
  prioridad TEXT NOT NULL DEFAULT 'media'
    CHECK (prioridad IN ('baja', 'media', 'alta')),
  fecha_vencimiento DATE,
  nota_id UUID REFERENCES notas(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- CHECKLIST ITEMS (pasos de tarea)
CREATE TABLE checklist_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tarea_id UUID REFERENCES tareas(id) ON DELETE CASCADE,
  texto TEXT NOT NULL,
  completada BOOLEAN NOT NULL DEFAULT false,
  orden INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RELACION TAREA-CATEGORIA
CREATE TABLE tarea_categorias (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tarea_id UUID REFERENCES tareas(id) ON DELETE CASCADE,
  categoria_id UUID REFERENCES categorias(id) ON DELETE CASCADE,
  UNIQUE(tarea_id, categoria_id)
);

-- RECORDATORIOS
CREATE TABLE recordatorios (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  titulo TEXT NOT NULL,
  descripcion TEXT NOT NULL DEFAULT '',
  fecha_hora TIMESTAMPTZ NOT NULL,
  tipo TEXT NOT NULL DEFAULT 'personalizado'
    CHECK (tipo IN ('nota', 'tarea', 'personalizado')),
  referencia_id UUID,
  completado BOOLEAN NOT NULL DEFAULT false,
  notificado BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- INDICES
CREATE INDEX idx_notas_user_id ON notas(user_id);
CREATE INDEX idx_tareas_user_id ON tareas(user_id);
CREATE INDEX idx_tareas_fecha_vencimiento ON tareas(fecha_vencimiento);
CREATE INDEX idx_recordatorios_fecha_hora ON recordatorios(fecha_hora);
CREATE INDEX idx_recordatorios_user_id ON recordatorios(user_id);
CREATE INDEX idx_categorias_user_id ON categorias(user_id);

-- ROW LEVEL SECURITY
ALTER TABLE notas ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE nota_categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE tareas ENABLE ROW LEVEL SECURITY;
ALTER TABLE checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarea_categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE recordatorios ENABLE ROW LEVEL SECURITY;

-- POLITICAS RLS
CREATE POLICY "Usuarios ven sus propias notas"
  ON notas FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuarios ven sus propias categorias"
  ON categorias FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuarios ven sus propias nota_categorias"
  ON nota_categorias FOR ALL
  USING (
    EXISTS (SELECT 1 FROM notas WHERE id = nota_id AND user_id = auth.uid())
  );

CREATE POLICY "Usuarios ven sus propias tareas"
  ON tareas FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuarios ven sus propios checklist_items"
  ON checklist_items FOR ALL
  USING (
    EXISTS (SELECT 1 FROM tareas WHERE id = tarea_id AND user_id = auth.uid())
  );

CREATE POLICY "Usuarios ven sus propias tarea_categorias"
  ON tarea_categorias FOR ALL
  USING (
    EXISTS (SELECT 1 FROM tareas WHERE id = tarea_id AND user_id = auth.uid())
  );

CREATE POLICY "Usuarios ven sus propios recordatorios"
  ON recordatorios FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
