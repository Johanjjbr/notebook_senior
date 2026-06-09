-- Enable Realtime for tables that need cross-device sync
alter publication supabase_realtime add table notas;
alter publication supabase_realtime add table categorias;
alter publication supabase_realtime add table nota_categorias;
alter publication supabase_realtime add table tareas;
alter publication supabase_realtime add table tarea_categorias;
alter publication supabase_realtime add table checklist_items;
alter publication supabase_realtime add table recordatorios;
