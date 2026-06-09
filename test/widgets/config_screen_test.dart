import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notebook_senior/configuracion/config_screen.dart';
import 'package:notebook_senior/core/providers/auth_provider.dart';
import 'test_helper.dart';

void main() {
  late MockAuthProvider auth;

  setUp(() {
    auth = MockAuthProvider();
    when(() => auth.user).thenReturn(null);
    when(() => auth.cargando).thenReturn(false);
    when(() => auth.error).thenReturn(null);
    when(() => auth.estaLogueado).thenReturn(false);
    when(() => auth.displayName).thenReturn('');
  });

  testWidgets('ConfigScreen shows all expected sections', (tester) async {
    await tester.pumpWidget(createTestApp(child: const ConfigScreen(), auth: auth));
    await tester.pumpAndSettle();

    expect(find.text('Configuración'), findsOneWidget);
    expect(find.text('Editar perfil'), findsOneWidget);
    expect(find.text('Tema oscuro'), findsOneWidget);
    expect(find.text('Información'), findsOneWidget);
    expect(find.text('Versión'), findsOneWidget);
  });

  testWidgets('ConfigScreen shows display name when set', (tester) async {
    when(() => auth.displayName).thenReturn('Test User');
    await tester.pumpWidget(createTestApp(child: const ConfigScreen(), auth: auth));
    await tester.pumpAndSettle();

    expect(find.text('Test User'), findsOneWidget);
  });

  testWidgets('ConfigScreen logout button exists and shows confirmation dialog',
      (tester) async {
    when(() => auth.logout()).thenAnswer((_) async {});

    await tester.pumpWidget(createTestApp(child: const ConfigScreen(), auth: auth));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Cerrar sesión'), 200);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('¿Estás seguro de cerrar sesión?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('ConfigScreen dark mode toggle exists', (tester) async {
    await tester.pumpWidget(createTestApp(child: const ConfigScreen(), auth: auth));
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('ConfigScreen edit profile dialogs work', (tester) async {
    when(() => auth.cambiarNombre(any())).thenAnswer((_) async {});
    when(() => auth.displayName).thenReturn('Original');

    await tester.pumpWidget(createTestApp(child: const ConfigScreen(), auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cambiar nombre'));
    await tester.pumpAndSettle();

    expect(find.text('Guardar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });
}
