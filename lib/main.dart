import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/supabase/client.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/notas_provider.dart';
import 'core/providers/tareas_provider.dart';
import 'core/providers/recordatorios_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/notificacion_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await SupabaseConfig.initialize();

  final notificacionService = NotificacionService();
  await notificacionService.initialize();
  final themeMode = await ThemeProvider.loadThemeMode();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(initialMode: themeMode)),
        ChangeNotifierProvider(create: (_) => NotasProvider()),
        ChangeNotifierProvider(create: (_) => TareasProvider()),
        ChangeNotifierProvider(create: (_) => RecordatoriosProvider()),
      ],
      child: const _AppLifecycleHandler(
        child: NotebookSeniorApp(),
      ),
    ),
  );
}

class _AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const _AppLifecycleHandler({required this.child});

  @override
  State<_AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<_AppLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(_onFirstFrame);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reprogramarNotificaciones();
    }
  }

  Future<void> _onFirstFrame(Duration _) async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.estaLogueado) return;
    if (!mounted) return;
    await context.read<RecordatoriosProvider>().cargarRecordatorios();
    if (!mounted) return;
    await context.read<TareasProvider>().cargarTareas();
    if (!mounted) return;
    await context.read<RecordatoriosProvider>().reprogramarPendientes();
    if (!mounted) return;
    await context.read<TareasProvider>().reprogramarPendientes();
  }

  void _reprogramarNotificaciones() {
    context.read<RecordatoriosProvider>().reprogramarPendientes();
    context.read<TareasProvider>().reprogramarPendientes();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
