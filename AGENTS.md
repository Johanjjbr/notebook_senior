# Notebook Senior — AGENTS.md

## Project Overview
Personal productivity app: Notes, Tasks, and Reminders with Supabase backend. Built with Flutter + Material 3.

## Tech Stack
- **Flutter** (stable)
- **Supabase** (auth, database, RLS)
- **go_router** (declarative routing + auth guards)
- **provider** (state management)
- **flutter_local_notifications** (push notifications)
- **flutter_dotenv** (secrets)

## Architecture
```
lib/
  main.dart                 -- Composition root (providers, supabase init)
  app.dart                  -- GoRouter + ShellRoute + NavigationBar
  auth/                     -- Login/Register screen
  dashboard/                -- Home/resumen screen
  notas/                    -- Notes CRUD (list + form)
  tareas/                   -- Tasks CRUD (list + form + checklist)
  recordatorios/            -- Reminders CRUD
  busqueda/                 -- Global search (notes + tasks)
  configuracion/            -- Settings/Profile/Logout
  core/
    providers/              -- ChangeNotifier providers (auth, notas, tareas, recordatorios)
    services/               -- NotificacionService (local notifications)
    supabase/               -- Supabase config & client init
    theme/                  -- AppTheme (colors + ThemeData)
  models/                   -- Nota, Tarea, Recordatorio, Categoria, ChecklistItem, enums
  widgets/                  -- EMPTY (shared widgets TBD)
```

Pattern: Screen → Provider (state + data access) → Supabase REST API. No repository/domain layer.

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

## Missing / To Do

### Critical
- [x] **Error handling**: Providers lack try-catch on DB calls → crash on network error
- [x] **Tests**: 19 unit tests covering all 4 providers (notas, tareas, recordatorios, auth). Uses `MockDatabaseService` + mocktail. 0 widget tests (require Supabase init)
- [x] **Repository layer**: Providers mix state + data access → Added `DatabaseService` abstract interface + `SupabaseDatabaseService` impl. Providers accept optional `DatabaseService` for DI/testing
- [x] **Checklist edit bug**: On task update, all checklist items are deleted/re-inserted losing completion state & IDs
- [x] **Dispose Supabase auth listener**: `onAuthStateChange.listen()` never cancelled (memory leak)

### High Priority
- [x] **Delete UI**: Added delete button in note/task cards via PopupMenuButton
- [x] **Archive UI**: Added archive/unarchive toggle in notes AppBar + PopupMenu
- [x] **Reminder edit**: Added edit functionality via dialog
- [x] **Navigation fix**: Dashboard uses fragile `findAncestorStateOfType` instead of `context.go`
- [x] **User feedback**: Added SnackBars on delete, archive, complete operations
- [ ] **Offline support**: No caching — all data requires network

### Medium Priority
- [x] **Dark theme**: Only lightTheme defined → Added darkTheme + ThemeProvider with shared_preferences persistence + toggle in settings
- [x] **Debounced search**: Fires on every keystroke → Added 300ms Timer debounce in global search
- [x] **Shared widgets**: `widgets/` empty → Extracted `DashboardCard`, `AccionRapida`, `CategoriaFilterChips`, `parseColor()`
- [x] **Per-operation loading states**: Single `_cargando` bool is too coarse → Split into `_cargandoLista`, `_guardando`, `_eliminando`, `_cargandoMas` per provider
- [x] **Pagination**: All data loaded at once → Added 20-item page pagination via `.range()` in all providers + scroll-to-load in screens
- [x] **Sorting options**: Notes/tasks sorted only by `updated_at DESC` → Added sort PopupMenuButton (updated_at, created_at, titulo, prioridad)
- [x] **Categoria copyWith**: Missing → Added `copyWith()` method
- [ ] **Localization**: All strings hardcoded in Spanish, no .arb files
- [ ] **README**: Still contains default Flutter template text

### Low Priority
- [ ] **CI/CD**: No GitHub Actions or pipeline
- [ ] **Image attachments**: Supabase Storage available but unused
- [ ] **Rich text editing**: Plain TextField, no markdown/flutter_quill
- [ ] **User profile editing**: No change email/password/display name
- [ ] **App icon / splash screen**: Defaults

## Commands
```bash
flutter run              # Run app
flutter analyze          # Lint check (flutter_lints)
flutter test             # Run tests
flutter build apk        # Build Android
```

## SQL Migrations
Located in `supabase/migrations/20250608_initial_schema.sql`.
Covers: notas, categorias, nota_categorias, tareas, checklist_items, tarea_categorias, recordatorios + RLS policies + indexes.
