import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';
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
    );
  }
}

class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  int _indiceActual(String location) {
    if (location.startsWith('/notas')) return 1;
    if (location.startsWith('/tareas')) return 2;
    if (location.startsWith('/recordatorios')) return 3;
    if (location.startsWith('/configuracion')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
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
              context.go('/notas');
              break;
            case 2:
              context.go('/tareas');
              break;
            case 3:
              context.go('/recordatorios');
              break;
            case 4:
              context.go('/configuracion');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt),
            label: 'Notas',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tareas',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm),
            label: 'Recordatorios',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
