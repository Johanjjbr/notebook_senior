# Notebook Senior

Personal productivity app: Notes, Tasks, and Reminders with Supabase backend.

## Stack

- **Flutter** (Material 3)
- **Supabase** (auth, database, RLS)
- **go_router** (declarative routing + auth guards)
- **provider** (state management)
- **flutter_local_notifications** (push notifications)

## Architecture

```
lib/
  main.dart                 -- Composition root
  app.dart                  -- GoRouter + ShellRoute + NavigationBar
  auth/                     -- Login/Register
  dashboard/                -- Home screen
  notas/                    -- Notes CRUD
  tareas/                   -- Tasks CRUD + checklist
  recordatorios/            -- Reminders CRUD
  busqueda/                 -- Global search
  configuracion/            -- Settings / Profile / Logout
  core/
    providers/              -- State management
    services/               -- NotificacionService
    supabase/               -- Supabase client
    theme/                  -- AppTheme (light + dark)
  data/                     -- DatabaseService (abstract + Supabase impl)
  models/                   -- Nota, Tarea, Recordatorio, Categoria, etc.
  widgets/                  -- Shared widgets
```

Pattern: Screen → Provider (state + data access) → DatabaseService → Supabase REST API.

## Features

- Auth (email/password, session persistence)
- Notes (grid, color picker, categories, archive, search)
- Tasks (list, priority, due date, inline toggle, checklist, notifications)
- Reminders (grouped, local push notifications)
- Dashboard (summary cards, quick actions)
- Global search (notes + tasks)
- Dark mode (persisted via shared_preferences)
- Material 3 theming
- Pagination (20 items/page)
- Pull-to-refresh on all lists

## Setup

1. Copy `.env.example` to `.env` and add your Supabase credentials.
2. Run the SQL migration in `supabase/migrations/`.
3. `flutter pub get`
4. `flutter run`

## Commands

```bash
flutter run              # Run app
flutter analyze          # Lint check
flutter test             # Run tests (19 unit tests)
flutter build apk        # Build Android
```
