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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotasProvider()),
        ChangeNotifierProvider(create: (_) => TareasProvider()),
        ChangeNotifierProvider(create: (_) => RecordatoriosProvider()),
      ],
      child: NotebookSeniorApp(),
    ),
  );
}
