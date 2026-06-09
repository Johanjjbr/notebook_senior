# Changelog

## [1.0.0] — 2026-06-09

### Added
- Initial release with full CRUD for Notes, Tasks, and Reminders
- Supabase auth (email/password), database, RLS, and Realtime
- Dashboard with summary cards and quick actions
- Global search with 300ms debounce
- Dark mode toggle with shared_preferences persistence
- Task notifications with due date scheduling
- Pagination (20 items/page) and pull-to-refresh
- Sorting and filtering (state, priority, scheduled)
- Material 3 light + dark theming
- 29 unit tests using mocktail
- Abstract DatabaseService interface for testability
