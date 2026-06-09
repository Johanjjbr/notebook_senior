# Notebook Senior

Personal productivity app: Notes, Tasks, and Reminders with Supabase backend.

## Stack

- **Flutter** (Material 3)
- **Supabase** (auth, database, RLS, realtime)
- **go_router** (declarative routing + auth guards)
- **provider** (state management)
- **flutter_local_notifications** (push notifications)
- **flutter_dotenv** (secrets)
- **shared_preferences** (theme persistence)
- **mocktail** (unit testing)

## Architecture

```
lib/
  main.dart                 -- Composition root
  app.dart                  -- GoRouter + ShellRoute + NavigationBar
  auth/                     -- Login/Register
  dashboard/                -- Home screen
  notas/                    -- Notes CRUD (grid, color, categories, archive)
  tareas/                   -- Tasks CRUD (checklist, priority, filters)
  recordatorios/            -- Reminders CRUD (push notifications)
  busqueda/                 -- Global search (notes + tasks)
  configuracion/            -- Settings / Profile / Logout / Dark mode
  core/
    providers/              -- AuthProvider, NotasProvider, TareasProvider,
                               RecordatoriosProvider, ThemeProvider
    services/               -- NotificacionService
    supabase/               -- Supabase client init
    theme/                  -- AppTheme (light + dark)
  data/                     -- DatabaseService (abstract) + SupabaseDatabaseService
  models/                   -- Nota, Tarea, Recordatorio, Categoria,
                               ChecklistItem, prioridad/tipo enums
  widgets/                  -- DashboardCard, CategoriaFilterChips, parseColor
```

Pattern: **Screen → Provider → DatabaseService → Supabase REST API**

## Features

- **Auth** — email/password login, register, logout, session persistence
- **Notes** — grid view, color picker, categories (M:N), archive/unarchive, search
- **Tasks** — list view, priority (baja/media/alta), due date, categories,
          inline toggle, checklist items, scheduled task filter
- **Reminders** — grouped (próximos/todos), local push notifications, scheduling
- **Dashboard** — summary cards (next reminder, today's tasks, recent notes),
                quick action buttons
- **Global search** — notes + tasks in one screen with 300ms debounce
- **Dark mode** — full theme toggle persisted via shared_preferences
- **Material 3** — light + dark ThemeData, responsive login layout
- **Pagination** — 20 items/page with scroll-to-load in all lists
- **Pull-to-refresh** — on all list screens
- **Realtime** — cross-device sync via Supabase Realtime subscriptions
- **Sorting** — by updated_at, created_at, titulo, prioridad
- **Loading states** — per-operation (loading list, saving, deleting, loading more)
- **SnackBar undo** — delete operations with restore action

## Testing

- **29 unit tests** covering all 4 providers:
  - AuthProvider (12 tests — login, register, logout, errors, loading states)
  - NotasProvider (7 tests — CRUD, search, error handling)
  - TareasProvider (5 tests — CRUD, filter, toggle, errors)
  - RecordatoriosProvider (5 tests — CRUD, próximos filter, errors)
- Uses `MockDatabaseService` + `mocktail` — no Supabase initialization needed
- 0 widget/integration tests (require Flutter rendering)

## Setup

1. Copy `.env.example` to `.env` and add your Supabase credentials.
2. Run the SQL migration in `supabase/migrations/`.
3. `flutter pub get`
4. `flutter run`

## Commands

```bash
flutter run              # Run app
flutter analyze          # Lint check
flutter test             # Run tests (29 unit tests)
flutter build apk        # Build Android
```
