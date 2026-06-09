-- Add recurrence support to tareas, recordatorios, and notas

ALTER TABLE tareas ADD COLUMN recurrencia TEXT NOT NULL DEFAULT 'none'
  CHECK (recurrencia IN ('none', 'diaria', 'semanal', 'mensual', 'anual'));
ALTER TABLE tareas ADD COLUMN recurrencia_fin TIMESTAMPTZ;

ALTER TABLE recordatorios ADD COLUMN recurrencia TEXT NOT NULL DEFAULT 'none'
  CHECK (recurrencia IN ('none', 'diaria', 'semanal', 'mensual', 'anual'));
ALTER TABLE recordatorios ADD COLUMN recurrencia_fin TIMESTAMPTZ;

ALTER TABLE notas ADD COLUMN recurrencia TEXT NOT NULL DEFAULT 'none'
  CHECK (recurrencia IN ('none', 'diaria', 'semanal', 'mensual', 'anual'));
ALTER TABLE notas ADD COLUMN recurrencia_fin TIMESTAMPTZ;
