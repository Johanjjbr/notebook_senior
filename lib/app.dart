import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'calendario/calendario_screen.dart';
import 'notas/notas_list_screen.dart';
import 'notas/nota_form_screen.dart';
import 'tareas/tareas_list_screen.dart';
import 'tareas/tarea_form_screen.dart';
import 'recordatorios/recordatorios_screen.dart';
import 'busqueda/busqueda_screen.dart';
import 'configuracion/config_screen.dart';

class NotebookSeniorApp extends StatelessWidget {
  const NotebookSeniorApp({super.key});

  GoRouter _buildRouter(AuthProvider auth) {
    return GoRouter(
      refreshListenable: auth,
      initialLocation: '/login',
      redirect: (context, state) {
        final estaLogueado = auth.estaLogueado;
        final ruta = state.matchedLocation;

        if (!estaLogueado && ruta != '/login') return '/login';
        if (estaLogueado && ruta == '/login') return '/';
        return null;
      },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/calendario',
            builder: (context, state) => const CalendarioScreen(),
          ),
          GoRoute(
            path: '/notas',
            builder: (context, state) => const NotasListScreen(),
            routes: [
              GoRoute(
                path: 'nueva',
                builder: (context, state) => const NotaFormScreen(),
              ),
              GoRoute(
                path: 'editar/:id',
                builder: (context, state) => NotaFormScreen(
                  notaId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/tareas',
            builder: (context, state) => const TareasListScreen(),
            routes: [
              GoRoute(
                path: 'nueva',
                builder: (context, state) => const TareaFormScreen(),
              ),
              GoRoute(
                path: 'editar/:id',
                builder: (context, state) => TareaFormScreen(
                  tareaId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/recordatorios',
            builder: (context, state) => const RecordatoriosScreen(),
          ),
          GoRoute(
            path: '/busqueda',
            builder: (context, state) => const BusquedaScreen(),
          ),
          GoRoute(
            path: '/configuracion',
            builder: (context, state) => const ConfigScreen(),
          ),
        ],
      ),
    ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final router = _buildRouter(auth);
    return MaterialApp.router(
      title: 'Notebook Senior',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      locale: const Locale('es'),
    );
  }
}

class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  int _indiceActual(String location) {
    if (location.startsWith('/calendario')) return 1;
    if (location.startsWith('/notas')) return 2;
    if (location.startsWith('/tareas')) return 3;
    if (location.startsWith('/recordatorios')) return 4;
    if (location.startsWith('/configuracion')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _indiceActual(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/calendario');
              break;
            case 2:
              context.go('/notas');
              break;
            case 3:
              context.go('/tareas');
              break;
            case 4:
              context.go('/recordatorios');
              break;
            case 5:
              context.go('/configuracion');
              break;
          }
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: l10n.dashboardTitle,
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt),
            label: l10n.notesTitle,
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: l10n.tasksTitle,
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm),
            label: l10n.remindersTitle,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: l10n.settingsTitle,
          ),
        ],
      ),
    );
  }
}
