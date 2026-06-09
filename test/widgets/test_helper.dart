import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notebook_senior/core/providers/auth_provider.dart';
import 'package:notebook_senior/core/providers/theme_provider.dart';
import 'package:notebook_senior/core/providers/notas_provider.dart';
import 'package:notebook_senior/core/providers/tareas_provider.dart';
import 'package:notebook_senior/core/providers/recordatorios_provider.dart';
import 'package:notebook_senior/l10n/app_localizations.dart';
import '../mocks/mock_database_service.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

Widget createTestApp({
  required Widget child,
  MockDatabaseService? db,
  AuthProvider? auth,
  ThemeMode themeMode = ThemeMode.light,
}) {
  final mockDb = db ?? MockDatabaseService();
  final themeProvider = ThemeProvider(initialMode: themeMode);

  return MaterialApp(
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
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth ?? MockAuthProvider(),
        ),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => NotasProvider(db: mockDb)),
        ChangeNotifierProvider(create: (_) => TareasProvider(db: mockDb)),
        ChangeNotifierProvider(create: (_) => RecordatoriosProvider(db: mockDb)),
      ],
      child: child,
    ),
  );
}
