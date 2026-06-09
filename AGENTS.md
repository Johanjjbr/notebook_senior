# Notebook Senior — AGENTS.md

## Project Overview
Personal productivity app: Notes, Tasks, and Reminders with Supabase backend. Built with Flutter + Material 3.

## Tech Stack
- **Flutter** (stable)
- **Supabase** (auth, database, RLS, realtime)
- **go_router** (declarative routing + auth guards)
- **provider** (state management)
- **flutter_local_notifications** (push notifications)
- **flutter_dotenv** (secrets)
- **flutter_localizations** + **intl** (l10n Spanish + English)
- **sqflite** (offline cache)
- **connectivity_plus** (network detection)
- **mocktail** (unit testing)

## Architecture
```
lib/
  main.dart                 -- Composition root (providers, supabase init, offline cache)
  app.dart                  -- GoRouter + ShellRoute + NavigationBar + l10n
  l10n/                     -- ARB files + generated AppLocalizations
  auth/                     -- Login/Register screen
  dashboard/                -- Home/resumen screen
  notas/                    -- Notes CRUD (list + form)
  tareas/                   -- Tasks CRUD (list + form + checklist)
  recordatorios/            -- Reminders CRUD
  busqueda/                 -- Global search (notes + tasks)
  configuracion/            -- Settings/Profile/Logout/Dark mode + profile editing
  core/
    providers/              -- ChangeNotifier providers (auth, notas, tareas, recordatorios, theme)
    services/               -- NotificacionService (local notifications)
    supabase/               -- Supabase config & client init
    theme/                  -- AppTheme (colors + ThemeData)
  data/
    database_service.dart   -- Abstract interface for DI/testing
    supabase_database_service.dart -- Supabase REST implementation
    cache/
      local_database.dart   -- SQLite cache tables
      cached_database_service.dart -- Offline-first wrapper
  models/                   -- Nota, Tarea, Recordatorio, Categoria, ChecklistItem, enums
  widgets/                  -- DashboardCard, CategoriaFilterChips, parseColor
```

Pattern: Screen → Provider (state + data access) → CachedDatabaseService | SupabaseDatabaseService → Supabase REST API

## Implemented Features
- [x] Auth: email/password login, register, logout, session persistence
- [x] Auth redirect: unauthenticated → /login
- [x] Notes: CRUD, grid view, color picker, categories (M:N), archive, search
- [x] Tasks: CRUD, list view, priority (baja/media/alta), due date, categories, inline toggle, checklist items
- [x] Reminders: CRUD, grouped list, local push notifications, scheduling
- [x] Dashboard: summary cards (next reminder, today's tasks, recent notes), quick actions
- [x] Global search: notes + tasks in one screen
- [x] Settings: profile info, app version, logout with confirmation
- [x] Pull-to-refresh on lists
- [x] Material 3 theming
- [x] Dark theme: full dark mode + ThemeProvider toggle
- [x] Web compatible: notifications disabled gracefully on web
- [x] Task notifications: scheduling local notifications for tasks with due dates
- [x] Task filter "Programadas": filter to show only scheduled (non-completed tasks with due dates)
- [x] Note dark mode text contrast: auto dark/light text based on note color luminance
- [x] Supabase RLS + indexes
- [x] Error handling: try-catch on all DB calls
- [x] Repository layer: DatabaseService abstract interface + SupabaseDatabaseService impl
- [x] Tests: 34 unit tests covering all 4 providers (auth: 17, notas: 7, tareas: 5, recordatorios: 5)
- [x] Checklist edit bug: fixed (preserves completion state & IDs)
- [x] Dispose Supabase auth listener: properly cancelled
- [x] Delete UI + Archive UI + Reminder edit + User feedback (SnackBars)
- [x] Navigation fix: uses `context.go` instead of `findAncestorStateOfType`
- [x] Dark theme: persisted via shared_preferences + toggle in settings
- [x] Debounced search: 300ms Timer in global search
- [x] Shared widgets: DashboardCard, CategoriaFilterChips, parseColor
- [x] Per-operation loading states: _cargandoLista, _guardando, _eliminando, _cargandoMas
- [x] Pagination: 20-item pages with scroll-to-load
- [x] Sorting: by updated_at, created_at, titulo, prioridad
- [x] Categoria copyWith: added
- [x] Full localization: Spanish + English via ARB files + flutter gen-l10n
- [x] Profile editing: change name, email, password from Settings
- [x] Offline support: SQLite cache via CachedDatabaseService + connectivity_plus
- [x] CI/CD: GitHub Actions (flutter analyze + flutter test)
- [x] CHANGELOG.md + LICENSE (MIT)

### Missing / To Do
- [ ] Widget/integration tests (require Flutter rendering)
- [ ] Rich text editing (flutter_quill)
- [ ] Image attachments (Supabase Storage)
- [ ] Custom app icon / splash screen
- [ ] User profile editing: email confirmation flow
- [ ] More granular offline sync (write queue for offline mutations)

## Commands
```bash
flutter run              # Run app
flutter analyze          # Lint check (0 issues)
flutter test             # Run tests (34 unit tests)
flutter gen-l10n         # Regenerate localization files
flutter build apk        # Build Android
```

## SQL Migrations
Located in `supabase/migrations/20250608_initial_schema.sql` + `20250609_enable_realtime.sql`.
Covers: notas, categorias, nota_categorias, tareas, checklist_items, tarea_categorias, recordatorios + RLS policies + indexes + realtime.
